`timescale 1ns / 1ps

// ǰ���䵥Ԫģ�� (�汾 3 - ʹ�����������)
module ForwardingUnit(
    input MEM_RegWrite,      // MEM �׶��Ƿ�д�Ĵ���
    input [4:0] MEM_rd,      // MEM �׶ε�Ŀ��Ĵ�����ַ
    input WB_RegWrite,       // WB �׶��Ƿ�д�Ĵ���
    input [4:0] WB_rd,       // WB �׶ε�Ŀ��Ĵ�����ַ
    input [4:0] EX_rs1,      // EX �׶ε�Դ�Ĵ���1��ַ
    input [4:0] EX_rs2,      // EX �׶ε�Դ�Ĵ���2��ַ
    output [1:0] ForwardA,   // EX_rs1 ��ǰ��������ź�
    output [1:0] ForwardB    // EX_rs2 ��ǰ��������ź�
);

    // --- �����м��źţ��ж�ƥ������ ---

    // �ж� EX_rs1 �Ƿ��� MEM �� WB �׶ε�Ŀ��Ĵ���ƥ��
    wire match_MEM_rs1 = MEM_RegWrite && (MEM_rd == EX_rs1);
    wire match_WB_rs1  = WB_RegWrite  && (WB_rd  == EX_rs1);

    // �ж� EX_rs2 �Ƿ��� MEM �� WB �׶ε�Ŀ��Ĵ���ƥ��
    wire match_MEM_rs2 = MEM_RegWrite && (MEM_rd == EX_rs2);
    wire match_WB_rs2  = WB_RegWrite  && (WB_rd  == EX_rs2);

    // --- ʹ����������� (?:) ʵ��ǰ�����߼� ---

    // ForwardA ���߼�:
    // ��� MEM �׶�ƥ�� (match_MEM_rs1 Ϊ��)���� ForwardA = 2'b10 (MEM ת��)��
    // ������� WB �׶�ƥ�� (match_WB_rs1 Ϊ��)���� ForwardA = 2'b01 (WB ת��)��
    // ����ForwardA = 2'b00 (��ת��)��
    // ����Ƕ�׽ṹ�Զ�ʵ���� MEM ������ WB ���߼���
    assign ForwardA = match_MEM_rs1 ? 2'b10 :
                      match_WB_rs1  ? 2'b01 :
                                      2'b00;

    // ForwardB ���߼�:
    // �� ForwardA ���ƣ������ EX_rs2 �����жϡ�
    assign ForwardB = match_MEM_rs2 ? 2'b10 :
                      match_WB_rs2  ? 2'b01 :
                                      2'b00;

endmodule