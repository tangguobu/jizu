module HazardDetectionUnit(
    input [4:0] IF_ID_rs1,     // 译码阶段（ID）的第一个源寄存器编号
    input [4:0] IF_ID_rs2,     // 译码阶段（ID）的第二个源寄存器编号
    input [4:0] ID_EX_rd,      // 执行阶段（EX）的目标寄存器编号
    input ID_EX_MemRead,       // 执行阶段是否进行内存读取操作
    input [2:0] ID_EX_NPCOp,   // 执行阶段的下一个 PC 操作控制信号
    output reg stall,           // 流水线停顿信号
    output reg IF_ID_flush,    // 取指 - 译码（IF - ID）流水线寄存器冲刷信号
    output reg PCWrite          // PC写使能信号
);

    // 定义内部信号，用于判断冒险条件
    wire is_load_use_hazard; // 标记是否存在Load-Use数据冒险
    wire is_control_hazard;  // 标记是否存在控制冒险

    // Load-Use数据冒险检测逻辑：
    // 当EX阶段是读内存指令(ID_EX_MemRead=1)，
    // 并且其目标寄存器不是零寄存器(ID_EX_rd != 5'b0)，
    // 并且该目标寄存器与ID阶段的任一源寄存器(IF_ID_rs1 或 IF_ID_rs2)相同。
    assign is_load_use_hazard = ID_EX_MemRead &&
                                (ID_EX_rd != 5'd0) &&
                                ((ID_EX_rd == IF_ID_rs1) || (ID_EX_rd == IF_ID_rs2));

    // 控制冒险检测逻辑：
    // 当EX阶段存在分支或跳转操作时 (ID_EX_NPCOp 不为 000)。
    assign is_control_hazard = (ID_EX_NPCOp != 3'b000);

    // 根据检测到的冒险情况，设置输出控制信号
    always @(*) begin
        // 默认情况下，不进行停顿和冲刷，允许PC写入
        stall = 1'b0;
        IF_ID_flush = 1'b0;
        PCWrite = 1'b1;

        // 优先处理Load-Use数据冒险
        if (is_load_use_hazard) begin
            stall = 1'b1;       // 发生Load-Use冒险，需要停顿流水线
            IF_ID_flush = 1'b0; // 停顿时不冲刷
            PCWrite = 1'b0;     // 停顿时禁止PC写入，以暂停取指
        end
        // 如果没有数据冒险，再检查控制冒险
        else if (is_control_hazard) begin
            stall = 1'b0;       // 不停顿
            IF_ID_flush = 1'b1; // 发生控制冒险，需要冲刷IF-ID寄存器
            PCWrite = 1'b1;     // 允许PC写入新地址
        end
        // 如果没有任何冒险，则保持默认值（正常运行）
        // else begin
        //     stall = 1'b0;
        //     IF_ID_flush = 1'b0;
        //     PCWrite = 1'b1;
        // end
    end

endmodule