`include "ctrl_encode_def.v"

module SCPU1(
    input      clk,            
    input      reset,          
    input [31:0]  inst_in,     
    input [31:0]  Data_in,     
    input INT,
    input MIO_ready,
    output    mem_w,          
    output [31:0] PC_out,     
    output [31:0] Addr_out,   
    output [31:0] Data_out,
    output CPU_MIO,
    output [2:0] DMType
);

    // 流水线控制信号定义
    wire stage1_enable, stage1_clear, stage2_clear;
    wire stage2_enable = 1'b1;  
    wire stage3_enable = 1'b1;  
    wire stage4_enable = 1'b1;
    wire pipeline_stall;
    
    // 流水线寄存器数据总线
    wire [63:0] stage1_input, stage1_output;
    wire [160:0] stage2_input, stage2_output;
    wire [110:0] stage3_input, stage3_output;
    wire [103:0] stage4_input, stage4_output;
    
    // 程序计数器相关信号
    wire [31:0] next_program_counter;
    wire program_counter_enable;
    
    // 指令解码字段提取
    wire [31:0] current_pc = stage1_output[63:32];
    wire [31:0] instruction_word = stage1_output[31:0];
    wire [6:0] opcode = instruction_word[6:0];
    wire [2:0] function3 = instruction_word[14:12];
    wire [6:0] function7 = instruction_word[31:25];
    wire [4:0] source_reg1 = instruction_word[19:15];
    wire [4:0] source_reg2 = instruction_word[24:20];
    wire [4:0] dest_reg = instruction_word[11:7];
    
    // 立即数字段提取与扩展
    wire [4:0] shift_amount = instruction_word[24:20];
    wire [11:0] i_immediate = instruction_word[31:20];
    wire [11:0] s_immediate = {instruction_word[31:25], instruction_word[11:7]};
    wire [11:0] b_immediate = {instruction_word[31], instruction_word[7], instruction_word[30:25], instruction_word[11:8]};
    wire [19:0] u_immediate = instruction_word[31:12];
    wire [19:0] j_immediate = {instruction_word[31], instruction_word[19:12], instruction_word[20], instruction_word[30:21]};
    wire [31:0] immediate_value;
    
    // 控制信号组
    wire write_enable, memory_write, alu_src_select, zero_flag;
    wire [1:0] write_data_source, gpr_source;
    wire [4:0] alu_ctrl_op;
    wire [2:0] pc_next_op, data_memory_type;
    wire [5:0] extend_operation;
    
    // 执行阶段信号解包
    wire reg_write_ex = stage2_output[160];
    wire mem_write_ex = stage2_output[159];
    wire [4:0] alu_operation = stage2_output[158:154];
    wire alu_source_sel = stage2_output[153];
    wire [1:0] gpr_select_ex = stage2_output[152:151];
    wire [1:0] write_data_sel_ex = stage2_output[150:149];
    wire [2:0] data_mem_type_ex = stage2_output[148:146];
    wire [31:0] read_data1_ex = stage2_output[142:111];
    wire [31:0] read_data2_ex = stage2_output[110:79];
    wire [31:0] immediate_ex = stage2_output[78:47];
    wire [4:0] rs1_ex = stage2_output[46:42];
    wire [4:0] rs2_ex = stage2_output[41:37];
    wire [4:0] rd_ex = stage2_output[36:32];
    wire [31:0] pc_ex = stage2_output[31:0];
    
    // 访存阶段信号解包
    wire [31:0] pc_mem = stage3_output[109:78];
    wire reg_write_mem = stage3_output[77];
    wire mem_write_mem = stage3_output[76];
    wire [1:0] write_data_sel_mem = stage3_output[75:74];
    wire [1:0] gpr_select_mem = stage3_output[73:72];
    wire [2:0] data_mem_type_mem = stage3_output[71:69];
    wire [31:0] alu_result_mem = stage3_output[68:37];
    wire [31:0] read_data2_mem = stage3_output[36:5];
    wire [4:0] rd_mem = stage3_output[4:0];
    
    // 写回阶段信号解包
    wire [31:0] pc_wb = stage4_output[103:72];
    wire reg_write_wb = stage4_output[71];
    wire [1:0] write_data_sel_wb = stage4_output[70:69];
    wire [31:0] mem_data_wb = stage4_output[68:37];
    wire [31:0] alu_result_wb = stage4_output[36:5];
    wire [4:0] rd_wb = stage4_output[4:0];
    
    // ALU相关信号
    wire [31:0] arithmetic_result;
    wire zero_condition;
    wire [2:0] next_pc_op = {stage2_output[145:144], stage2_output[143] & zero_condition};
    
    // 数据前递信号
    wire [1:0] forward_path_a, forward_path_b;
    wire [31:0] forwarded_data_a, forwarded_data_b, alu_input_b;
    
    // 寄存器文件信号
    wire [31:0] reg_read_data1, reg_read_data2;
    reg [31:0] register_data;
    
    // 冒险检测信号
    wire load_use_hazard = write_data_sel_ex[0];
    wire branch_jump_taken = |next_pc_op;
    
    // ========== 模块实例化部分 ==========
    
    // 程序计数器模块
    PC program_counter_unit (
       .clk(clk),
       .rst(reset),
       .NPC(next_program_counter),
       .PC(PC_out)
    );

    // 流水线寄存器组实例化
    GRE_array #(200) pipeline_stage1 (
       .Clk(clk), .Rst(reset), .write_enable(stage1_enable),
       .flush(stage1_clear), .in(stage1_input), .out(stage1_output)
    );

    GRE_array #(200) pipeline_stage2 (
       .Clk(clk), .Rst(reset), .write_enable(stage2_enable),
       .flush(stage2_clear), .in(stage2_input), .out(stage2_output)
    );

    GRE_array #(200) pipeline_stage3 (
       .Clk(clk), .Rst(reset), .write_enable(stage3_enable),
       .flush(1'b0), .in(stage3_input), .out(stage3_output)
    );

    GRE_array #(200) pipeline_stage4 (
       .Clk(clk), .Rst(reset), .write_enable(stage4_enable),
       .flush(1'b0), .in(stage4_input), .out(stage4_output)
    );

    // 控制单元
    ctrl control_unit (
       .Op(opcode), .Funct7(function7), .Funct3(function3), .Zero(zero_flag),
       .RegWrite(write_enable), .MemWrite(memory_write), .EXTOp(extend_operation),
       .ALUOp(alu_ctrl_op), .NPCOp(pc_next_op), .ALUSrc(alu_src_select),
       .GPRSel(gpr_source), .WDSel(write_data_source), .DMType(data_memory_type)
    );

    // 立即数扩展单元
    EXT immediate_extender(
        .iimm_shamt(shift_amount), .iimm(i_immediate), .simm(s_immediate), 
        .bimm(b_immediate), .uimm(u_immediate), .jimm(j_immediate),
        .EXTOp(extend_operation), .immout(immediate_value)
    );

    // 寄存器文件
    RF register_file (
       .clk(clk), .rst(reset), .RFWr(reg_write_wb),  
       .A1(source_reg1), .A2(source_reg2), .A3(rd_wb),  
       .WD(register_data), .RD1(reg_read_data1), .RD2(reg_read_data2)
    );

    // 冒险检测单元
    HazardDetectionUnit hazard_detector (
       .IF_ID_rs1(source_reg1), .IF_ID_rs2(source_reg2), .ID_EX_rd(rd_ex),
       .ID_EX_MemRead(load_use_hazard), .ID_EX_NPCOp(next_pc_op),
       .stall(pipeline_stall), .IF_ID_flush(stage1_clear), .PCWrite(program_counter_enable)
    );
    
    // 数据前递单元
    ForwardingUnit data_forwarder (
       .MEM_RegWrite(reg_write_mem), .MEM_rd(rd_mem),
       .WB_RegWrite(reg_write_wb), .WB_rd(rd_wb),
       .EX_rs1(rs1_ex), .ForwardA(forward_path_a),
       .EX_rs2(rs2_ex), .ForwardB(forward_path_b)
    );

    // ALU算术逻辑单元
    alu arithmetic_unit (
       .A(forwarded_data_a), .B(alu_input_b), .ALUOp(alu_operation),
       .C(arithmetic_result), .Zero(zero_condition), .PC(pc_ex)
    );

    // 下一PC计算单元
    NPC next_pc_calculator (
       .PC(PC_out), .PC_EX(pc_ex), .NPCOp(next_pc_op), .IMM(immediate_ex),
       .NPC(next_program_counter), .PCWrite(program_counter_enable), .aluout(arithmetic_result)
    );

    // ========== 组合逻辑赋值部分 ==========
    
    // 流水线数据流连接
    assign stage1_input = {PC_out, inst_in};
    assign stage2_input = {write_enable, memory_write, alu_ctrl_op, alu_src_select, 
                          gpr_source, write_data_source, data_memory_type, pc_next_op, 
                          reg_read_data1, reg_read_data2, immediate_value, 
                          source_reg1, source_reg2, dest_reg, current_pc};
    assign stage3_input = {pc_ex, reg_write_ex, mem_write_ex, write_data_sel_ex, 
                          gpr_select_ex, data_mem_type_ex, arithmetic_result, 
                          forwarded_data_b, rd_ex};
    assign stage4_input = {pc_mem, reg_write_mem, write_data_sel_mem, 
                          Data_in, alu_result_mem, rd_mem};
    
    // 流水线控制逻辑
    assign stage2_clear = pipeline_stall | branch_jump_taken;
    assign stage1_enable = ~pipeline_stall;
    
    // 数据前递多路选择器
    assign forwarded_data_a = (forward_path_a == 2'b00) ? read_data1_ex :
                             (forward_path_a == 2'b01) ? register_data :
                             (forward_path_a == 2'b10) ? alu_result_mem : 32'b0;
    assign forwarded_data_b = (forward_path_b == 2'b00) ? read_data2_ex :
                             (forward_path_b == 2'b01) ? register_data :
                             (forward_path_b == 2'b10) ? alu_result_mem : 32'b0;
    assign alu_input_b = alu_source_sel ? immediate_ex : forwarded_data_b;
    
    // 输出端口连接
    assign Addr_out = alu_result_mem;
    assign Data_out = read_data2_mem;
    assign mem_w = mem_write_mem;
    assign DMType = data_mem_type_mem;

    // ========== 时序逻辑部分 ==========
    
    // 写回数据选择逻辑
    always @(*) begin
        case(write_data_sel_wb)  
            `WDSel_FromALU: register_data = alu_result_wb;
            `WDSel_FromMEM: register_data = mem_data_wb;
            `WDSel_FromPC:  register_data = pc_wb + 4;
            default: register_data = 32'b0;
        endcase
    end

endmodule