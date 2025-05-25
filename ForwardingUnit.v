`timescale 1ns / 1ps

// 前向传输单元模块 (版本 3 - 使用条件运算符)
module ForwardingUnit(
    input MEM_RegWrite,      // MEM 阶段是否写寄存器
    input [4:0] MEM_rd,      // MEM 阶段的目标寄存器地址
    input WB_RegWrite,       // WB 阶段是否写寄存器
    input [4:0] WB_rd,       // WB 阶段的目标寄存器地址
    input [4:0] EX_rs1,      // EX 阶段的源寄存器1地址
    input [4:0] EX_rs2,      // EX 阶段的源寄存器2地址
    output [1:0] ForwardA,   // EX_rs1 的前向传输控制信号
    output [1:0] ForwardB    // EX_rs2 的前向传输控制信号
);

    // --- 定义中间信号，判断匹配条件 ---

    // 判断 EX_rs1 是否与 MEM 或 WB 阶段的目标寄存器匹配
    wire match_MEM_rs1 = MEM_RegWrite && (MEM_rd == EX_rs1);
    wire match_WB_rs1  = WB_RegWrite  && (WB_rd  == EX_rs1);

    // 判断 EX_rs2 是否与 MEM 或 WB 阶段的目标寄存器匹配
    wire match_MEM_rs2 = MEM_RegWrite && (MEM_rd == EX_rs2);
    wire match_WB_rs2  = WB_RegWrite  && (WB_rd  == EX_rs2);

    // --- 使用条件运算符 (?:) 实现前向传输逻辑 ---

    // ForwardA 的逻辑:
    // 如果 MEM 阶段匹配 (match_MEM_rs1 为真)，则 ForwardA = 2'b10 (MEM 转发)。
    // 否则，如果 WB 阶段匹配 (match_WB_rs1 为真)，则 ForwardA = 2'b01 (WB 转发)。
    // 否则，ForwardA = 2'b00 (不转发)。
    // 这种嵌套结构自动实现了 MEM 优先于 WB 的逻辑。
    assign ForwardA = match_MEM_rs1 ? 2'b10 :
                      match_WB_rs1  ? 2'b01 :
                                      2'b00;

    // ForwardB 的逻辑:
    // 与 ForwardA 类似，但针对 EX_rs2 进行判断。
    assign ForwardB = match_MEM_rs2 ? 2'b10 :
                      match_WB_rs2  ? 2'b01 :
                                      2'b00;

endmodule