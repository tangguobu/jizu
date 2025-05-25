module HazardDetectionUnit(
    input [4:0] IF_ID_rs1,     // ����׶Σ�ID���ĵ�һ��Դ�Ĵ������
    input [4:0] IF_ID_rs2,     // ����׶Σ�ID���ĵڶ���Դ�Ĵ������
    input [4:0] ID_EX_rd,      // ִ�н׶Σ�EX����Ŀ��Ĵ������
    input ID_EX_MemRead,       // ִ�н׶��Ƿ�����ڴ��ȡ����
    input [2:0] ID_EX_NPCOp,   // ִ�н׶ε���һ�� PC ���������ź�
    output reg stall,           // ��ˮ��ͣ���ź�
    output reg IF_ID_flush,    // ȡָ - ���루IF - ID����ˮ�߼Ĵ�����ˢ�ź�
    output reg PCWrite          // PCдʹ���ź�
);

    // �����ڲ��źţ������ж�ð������
    wire is_load_use_hazard; // ����Ƿ����Load-Use����ð��
    wire is_control_hazard;  // ����Ƿ���ڿ���ð��

    // Load-Use����ð�ռ���߼���
    // ��EX�׶��Ƕ��ڴ�ָ��(ID_EX_MemRead=1)��
    // ������Ŀ��Ĵ���������Ĵ���(ID_EX_rd != 5'b0)��
    // ���Ҹ�Ŀ��Ĵ�����ID�׶ε���һԴ�Ĵ���(IF_ID_rs1 �� IF_ID_rs2)��ͬ��
    assign is_load_use_hazard = ID_EX_MemRead &&
                                (ID_EX_rd != 5'd0) &&
                                ((ID_EX_rd == IF_ID_rs1) || (ID_EX_rd == IF_ID_rs2));

    // ����ð�ռ���߼���
    // ��EX�׶δ��ڷ�֧����ת����ʱ (ID_EX_NPCOp ��Ϊ 000)��
    assign is_control_hazard = (ID_EX_NPCOp != 3'b000);

    // ���ݼ�⵽��ð�������������������ź�
    always @(*) begin
        // Ĭ������£�������ͣ�ٺͳ�ˢ������PCд��
        stall = 1'b0;
        IF_ID_flush = 1'b0;
        PCWrite = 1'b1;

        // ���ȴ���Load-Use����ð��
        if (is_load_use_hazard) begin
            stall = 1'b1;       // ����Load-Useð�գ���Ҫͣ����ˮ��
            IF_ID_flush = 1'b0; // ͣ��ʱ����ˢ
            PCWrite = 1'b0;     // ͣ��ʱ��ֹPCд�룬����ͣȡָ
        end
        // ���û������ð�գ��ټ�����ð��
        else if (is_control_hazard) begin
            stall = 1'b0;       // ��ͣ��
            IF_ID_flush = 1'b1; // ��������ð�գ���Ҫ��ˢIF-ID�Ĵ���
            PCWrite = 1'b1;     // ����PCд���µ�ַ
        end
        // ���û���κ�ð�գ��򱣳�Ĭ��ֵ���������У�
        // else begin
        //     stall = 1'b0;
        //     IF_ID_flush = 1'b0;
        //     PCWrite = 1'b1;
        // end
    end

endmodule