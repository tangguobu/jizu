`timescale 1ns / 1ps

// ������ͨ�üĴ������� (�汾 2 - ���/ʱ�����)
module GRE_array #(parameter WIDTH = 200) (
    input Clk,               // ʱ���ź�
    input Rst,               // ��λ�ź� (��������Ч)
    input write_enable,      // дʹ���ź�
    input flush,             // ��ˢ�ź�
    input [WIDTH-1:0] in,    // ��������
    output reg [WIDTH-1:0] out // ������� (�Ĵ���)
);

    // ����һ�� wire ���͵��źţ�����Ĵ�������һ��״ֵ̬��
    // �ⲿ��������߼���
    wire [WIDTH-1:0] next_out_value;

    // ʹ�� assign �����������һ��״ֵ̬��
    // ��� flush �ź�Ϊ�ߣ�����һ��״̬Ϊȫ 0��
    // ������һ��״̬Ϊ�������� in��
    assign next_out_value = flush ? {WIDTH{1'b0}} : in;

    // ʱ���߼����֣�
    // ��ʱ�������ػ�λ�ź������ش�����
    always @(posedge Clk or posedge Rst) begin
        // ��鸴λ�ź� (������ȼ�)
        // ��� Rst Ϊ�ߣ��������������λΪ 0��
        if (Rst) begin
            out <= {WIDTH{1'b0}};
        end
        // ���û�и�λ������дʹ�� (write_enable) Ϊ�ߣ�
        // ����ʱ�ӱ��ؽ�����õ���һ��״ֵ̬ (next_out_value) ���浽����Ĵ�����
        else if (write_enable) begin
            out <= next_out_value;
        end
        // ���û�и�λ��дʹ��Ϊ�ͣ�������Ĵ��������䵱ǰֵ (������Ϊ)��
    end

endmodule