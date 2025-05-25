`timescale 1ns / 1ps

// 参数化通用寄存器阵列 (版本 2 - 组合/时序分离)
module GRE_array #(parameter WIDTH = 200) (
    input Clk,               // 时钟信号
    input Rst,               // 复位信号 (上升沿有效)
    input write_enable,      // 写使能信号
    input flush,             // 冲刷信号
    input [WIDTH-1:0] in,    // 输入数据
    output reg [WIDTH-1:0] out // 输出数据 (寄存器)
);

    // 定义一个 wire 类型的信号，代表寄存器的下一个状态值。
    // 这部分是组合逻辑。
    wire [WIDTH-1:0] next_out_value;

    // 使用 assign 语句来计算下一个状态值：
    // 如果 flush 信号为高，则下一个状态为全 0；
    // 否则，下一个状态为输入数据 in。
    assign next_out_value = flush ? {WIDTH{1'b0}} : in;

    // 时序逻辑部分：
    // 在时钟上升沿或复位信号上升沿触发。
    always @(posedge Clk or posedge Rst) begin
        // 检查复位信号 (最高优先级)
        // 如果 Rst 为高，则立即将输出复位为 0。
        if (Rst) begin
            out <= {WIDTH{1'b0}};
        end
        // 如果没有复位，并且写使能 (write_enable) 为高，
        // 则在时钟边沿将计算好的下一个状态值 (next_out_value) 锁存到输出寄存器。
        else if (write_enable) begin
            out <= next_out_value;
        end
        // 如果没有复位且写使能为低，则输出寄存器保持其当前值 (隐含行为)。
    end

endmodule