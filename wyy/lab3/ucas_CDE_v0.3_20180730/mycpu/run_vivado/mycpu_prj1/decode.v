`timescale 1ns / 1ps
//*************************************************************************
//   > �ļ���: decode.v
//   > ����  :�弶��ˮCPU������ģ��
//   > ����  : LOONGSON
//   > ����  : 2016-04-14
//*************************************************************************
module decode(                      // ���뼶
    input              ID_valid,    // ���뼶��Ч�ź�
    input      [ 63:0] IF_ID_bus_r, // IF->ID����
    input      [ 31:0] rs_value_in,    // ��һԴ������ֵ
    input      [ 31:0] rt_value_in,    // �ڶ�Դ������ֵ
    output     [  4:0] rs,          // ��һԴ��������ַ 
    output     [  4:0] rt,          // �ڶ�Դ��������ַ
    output     [ 32:0] jbr_bus,     // ��ת����
//  output             inst_jbr,    // ָ��Ϊ��ת��ָ֧��,�弶��ˮ����Ҫ
    output             ID_over,     // IDģ��ִ�����
    output     [166:0] ID_EXE_bus,  // ID->EXE����
    
    //5����ˮ����
    input              IF_over,     //���ڷ�ָ֧���Ҫ���ź�
    input      [  4:0] EXE_wdest,   // EXE��Ҫд�ؼĴ����ѵ�Ŀ���ַ��
    input      [  4:0] MEM_wdest,   // MEM��Ҫд�ؼĴ����ѵ�Ŀ���ַ��
    input              EXE_wen,
    input      [ 31:0] EXE_wdata,
    input              MEM_wen,
    input      [ 31:0] MEM_wdata,
    input      [  4:0] WB_wdest    // WB��Ҫд�ؼĴ����ѵ�Ŀ���ַ��

);
//-----{IF->ID����}begin
    wire [31:0] pc;
    wire [31:0] inst;
    assign {pc, inst} = IF_ID_bus_r;  // IF->ID���ߴ�PC��ָ��
    wire [31:0] rs_value;
    wire [31:0] rt_value;

//-----{IF->ID����}end

//-----{ָ������}begin
    wire [5:0] op;       
    wire [4:0] rd;       
    wire [4:0] sa;      
    wire [5:0] funct;    
    wire [15:0] imm;     
    wire [15:0] offset;  
    wire [25:0] target;  
    wire [2:0] cp0r_sel;

    assign op     = inst[31:26];  // ������
    assign rs     = inst[25:21];  // Դ������1
    assign rt     = inst[20:16];  // Դ������2
    assign rd     = inst[15:11];  // Ŀ�������
    assign sa     = inst[10:6];   // �����򣬿��ܴ��ƫ����
    assign funct  = inst[5:0];    // ������
    assign imm    = inst[15:0];   // ������
    assign offset = inst[15:0];   // ��ַƫ����
    assign target = inst[25:0];   // Ŀ���ַ
    assign cp0r_sel= inst[2:0];   // cp0�Ĵ�����select��

    // ʵ��ָ���б�
    wire inst_ADDU, inst_SUBU , inst_SLT , inst_AND;
    wire inst_NOR , inst_OR   , inst_XOR , inst_SLL;
    wire inst_SRL , inst_ADDIU, inst_BEQ , inst_BNE;
    wire inst_LW  , inst_SW   , inst_LUI , inst_J;
    wire inst_SLTU, inst_JALR , inst_JR  , inst_SLLV;
    wire inst_SRA , inst_SRAV , inst_SRLV, inst_SLTIU;
    wire inst_SLTI, inst_BGEZ , inst_BGTZ, inst_BLEZ;
    wire inst_BLTZ, inst_LB   , inst_LBU , inst_SB;
    wire inst_ANDI, inst_ORI  , inst_XORI, inst_JAL;
    wire inst_MULT, inst_MFLO , inst_MFHI, inst_MTLO;
    wire inst_MTHI, inst_MFC0 , inst_MTC0;
    wire inst_ERET, inst_SYSCALL;
    
    wire inst_ADDI, inst_ADD, inst_SUB;
    
    wire op_zero;  // ������ȫ0
    wire sa_zero;  // sa��ȫ0
    assign op_zero = ~(|op);
    assign sa_zero = ~(|sa);
    assign inst_ADD = op_zero & sa_zero & (funct == 6'b100000);
    assign inst_ADDU  = op_zero & sa_zero    & (funct == 6'b100001);//�޷��żӷ�
    assign inst_SUB = op_zero & sa_zero & (funct == 6'b100010);
    assign inst_SUBU  = op_zero & sa_zero    & (funct == 6'b100011);//�޷��ż���
    assign inst_SLT   = op_zero & sa_zero    & (funct == 6'b101010);//С������λ
    assign inst_SLTU  = op_zero & sa_zero    & (funct == 6'b101011);//�޷���С����
    assign inst_JALR  = op_zero & (rt==5'd0) & (rd==5'd31)
                      & sa_zero & (funct == 6'b001001);         //��ת�Ĵ���������
    assign inst_JR    = op_zero & (rt==5'd0) & (rd==5'd0 )
                      & sa_zero & (funct == 6'b001000);             //��ת�Ĵ���
    assign inst_AND   = op_zero & sa_zero    & (funct == 6'b100100);//������
    assign inst_NOR   = op_zero & sa_zero    & (funct == 6'b100111);//�������
    assign inst_OR    = op_zero & sa_zero    & (funct == 6'b100101);//������
    assign inst_XOR   = op_zero & sa_zero    & (funct == 6'b100110);//�������
    assign inst_SLL   = op_zero & (rs==5'd0) & (funct == 6'b000000);//�߼�����
    assign inst_SLLV  = op_zero & sa_zero    & (funct == 6'b000100);//�����߼�����
    assign inst_SRA   = op_zero & (rs==5'd0) & (funct == 6'b000011);//��������
    assign inst_SRAV  = op_zero & sa_zero    & (funct == 6'b000111);//������������
    assign inst_SRL   = op_zero & (rs==5'd0) & (funct == 6'b000010);//�߼�����
    assign inst_SRLV  = op_zero & sa_zero    & (funct == 6'b000110);//�����߼�����
    assign inst_MULT  = op_zero & (rd==5'd0)
                      & sa_zero & (funct == 6'b011000);             //�˷�
    assign inst_MFLO  = op_zero & (rs==5'd0) & (rt==5'd0)
                      & sa_zero & (funct == 6'b010010);             //��LO��ȡ
    assign inst_MFHI  = op_zero & (rs==5'd0) & (rt==5'd0)
                      & sa_zero & (funct == 6'b010000);             //��HI��ȡ
    assign inst_MTLO  = op_zero & (rt==5'd0) & (rd==5'd0)
                      & sa_zero & (funct == 6'b010011);             //��LOд����
    assign inst_MTHI  = op_zero & (rt==5'd0) & (rd==5'd0)
                      & sa_zero & (funct == 6'b010001);             //��HIд����
    assign inst_ADDIU = (op == 6'b001001);             //�������޷��żӷ�
    assign inst_ADDI = (op == 6'b001000);
    assign inst_SLTI  = (op == 6'b001010);             //С������������λ
    assign inst_SLTIU = (op == 6'b001011);             //С������������λ���޷��ţ�
    assign inst_BEQ   = (op == 6'b000100);             //�ж������ת
    assign inst_BGEZ  = (op == 6'b000001) & (rt==5'd1);//���ڵ���0��ת
    assign inst_BGTZ  = (op == 6'b000111) & (rt==5'd0);//����0��ת
    assign inst_BLEZ  = (op == 6'b000110) & (rt==5'd0);//С�ڵ���0��ת
    assign inst_BLTZ  = (op == 6'b000001) & (rt==5'd0);//С��0��ת
    assign inst_BNE   = (op == 6'b000101);             //�жϲ�����ת
    assign inst_LW    = (op == 6'b100011);             //���ڴ�װ����
    assign inst_SW    = (op == 6'b101011);             //���ڴ�洢��
    assign inst_LB    = (op == 6'b100000);             //load�ֽڣ�������չ��
    assign inst_LBU   = (op == 6'b100100);             //load�ֽڣ��޷�����չ��
    assign inst_SB    = (op == 6'b101000);             //���ڴ�洢�ֽ�
    assign inst_ANDI  = (op == 6'b001100);             //��������
    assign inst_LUI   = (op == 6'b001111) & (rs==5'd0);//������װ�ظ߰��ֽ�
    assign inst_ORI   = (op == 6'b001101);             //��������
    assign inst_XORI  = (op == 6'b001110);             //���������
    assign inst_J     = (op == 6'b000010);             //��ת
    assign inst_JAL   = (op == 6'b000011);             //��ת������
    assign inst_MFC0    = (op == 6'b010000) & (rs==5'd0) 
                        & sa_zero & (funct[5:3] == 3'b000); // ��cp0�Ĵ���װ��
    assign inst_MTC0    = (op == 6'b010000) & (rs==5'd4)
                        & sa_zero & (funct[5:3] == 3'b000); // ��cp0�Ĵ����洢
    assign inst_SYSCALL = (op == 6'b000000) & (funct == 6'b001100); // ϵͳ����
    assign inst_ERET    = (op == 6'b010000) & (rs==5'd16) & (rt==5'd0)
                        & (rd==5'd0) & sa_zero & (funct == 6'b011000);//�쳣����
    
    //��ת��ָ֧��
    wire inst_jr;    //�Ĵ�����תָ��
    wire inst_j_link;//������תָ��
    wire inst_jbr;   //���з�֧��תָ��
    assign inst_jr     = inst_JALR | inst_JR;
    assign inst_j_link = inst_JAL | inst_JALR;
    assign inst_jbr = inst_J    | inst_JAL  | inst_jr
                    | inst_BEQ  | inst_BNE  | inst_BGEZ
                    | inst_BGTZ | inst_BLEZ | inst_BLTZ;
        
    //load store
    wire inst_load;
    wire inst_store;
    assign inst_load  = inst_LW | inst_LB | inst_LBU;  // loadָ��
    assign inst_store = inst_SW | inst_SB;             // storeָ��
    
    //alu��������
    wire inst_add, inst_sub, inst_slt,inst_sltu;
    wire inst_and, inst_nor, inst_or, inst_xor;
    wire inst_sll, inst_srl, inst_sra,inst_lui;
    assign inst_add = inst_ADDU | inst_ADDIU | inst_load
                    | inst_store | inst_j_link;            // ���ӷ�
    assign inst_sub = inst_SUBU;                           // ����
    assign inst_slt = inst_SLT | inst_SLTI;                // �з���С����λ
    assign inst_sltu= inst_SLTIU | inst_SLTU;              // �޷���С����λ
    assign inst_and = inst_AND | inst_ANDI;                // �߼���
    assign inst_nor = inst_NOR;                            // �߼����
    assign inst_or  = inst_OR  | inst_ORI;                 // �߼���
    assign inst_xor = inst_XOR | inst_XORI;                // �߼����
    assign inst_sll = inst_SLL | inst_SLLV;                // �߼�����
    assign inst_srl = inst_SRL | inst_SRLV;                // �߼�����
    assign inst_sra = inst_SRA | inst_SRAV;                // ��������
    assign inst_lui = inst_LUI;                            // ������װ�ظ�λ
    
    //ʹ��sa����Ϊƫ��������λָ��
    wire inst_shf_sa;
    assign inst_shf_sa =  inst_SLL | inst_SRL | inst_SRA;
    
    //������������չ��ʽ����
    wire inst_imm_zero; //������0��չ
    wire inst_imm_sign; //������������չ
    assign inst_imm_zero = inst_ANDI  | inst_LUI  | inst_ORI | inst_XORI;
    assign inst_imm_sign = inst_ADDIU | inst_SLTI | inst_SLTIU
                         | inst_load | inst_store;
    
    //����Ŀ�ļĴ����ŷ���
    wire inst_wdest_rt;  // �Ĵ�����д���ַΪrt��ָ��
    wire inst_wdest_31;  // �Ĵ�����д���ַΪ31��ָ��
    wire inst_wdest_rd;  // �Ĵ�����д���ַΪrd��ָ��
    assign inst_wdest_rt = inst_imm_zero | inst_ADDIU | inst_SLTI
                         | inst_SLTIU | inst_load | inst_MFC0;
    assign inst_wdest_31 = inst_JAL;
    assign inst_wdest_rd = inst_ADDU | inst_SUBU | inst_SLT  | inst_SLTU
                         | inst_JALR | inst_AND  | inst_NOR  | inst_OR 
                            | inst_XOR  | inst_SLL  | inst_SLLV | inst_SRA 
                         | inst_SRAV | inst_SRL  | inst_SRLV
                         | inst_MFHI | inst_MFLO;
                         
    //����Դ�Ĵ����ŷ���
    wire inst_no_rs;  //ָ��rs���0���Ҳ��ǴӼĴ����Ѷ�rs������
    wire inst_no_rt;  //ָ��rt���0���Ҳ��ǴӼĴ����Ѷ�rt������
    assign inst_no_rs = inst_MTC0 | inst_SYSCALL | inst_ERET;
    assign inst_no_rt = inst_ADDIU | inst_SLTI | inst_SLTIU
                      | inst_BGEZ  | inst_load | inst_imm_zero
                      | inst_J     | inst_JAL  | inst_MFC0
                      | inst_SYSCALL;
//-----{ָ������}end
// 这里是数据前推
    wire rs_EXE_wait;
    wire rs_MEM_wait;
    wire rt_EXE_wait;
    wire rt_MEM_wait;
    assign rs_EXE_wait = ~inst_no_rs & (rs != 5'd0) & EXE_wen & (rs == EXE_wdest);
    assign rs_MEM_wait = ~inst_no_rs & (rs != 5'd0) & MEM_wen & (rs == MEM_wdest);    
    assign rt_EXE_wait = ~inst_no_rt & (rt != 5'd0) & EXE_wen & (rt == EXE_wdest);
    assign rt_MEM_wait = ~inst_no_rt & (rt != 5'd0) & MEM_wen & (rt == MEM_wdest);
    assign rs_value = rs_EXE_wait ?  EXE_wdata : (rs_MEM_wait ? MEM_wdata : rs_value_in);
    assign rt_value = rt_EXE_wait ?  EXE_wdata : (rt_MEM_wait ? MEM_wdata : rt_value_in);
// 前递试图用if语句判断失败
//    always @(*)
//    begin
//        if (~inst_no_rs)
//        begin
//            if((EXE_wen == 1'b1) && (EXE_wdest == rs))
//            begin
//                rs_value <= EXE_wdata;
//            end
//            else if((MEM_wen == 1'b1) && (MEM_wdest == rs))
//            begin
//                rs_value <= MEM_wdata;
//            end
//            else
//            begin
//                rs_value <= rs_value_r;
//            end
//        end
//    end
//    always @(*)
//    begin
//        if (~inst_no_rt)
//        begin
//            if((EXE_wen == 1'b1) && (EXE_wdest == rs))
//            begin
//                rt_value <= EXE_wdata;
//            end
//            else if((MEM_wen == 1'b1) && (MEM_wdest == rs))
//            begin
//                rt_value <= MEM_wdata;
//            end
//            else
//            begin
//                rt_value <= rs_value_r;
//            end
//        end
//    end
    
    
//-----{��ָ֧��ִ��}begin
   //bd_pc,��֧��תָ���������Ϊ�ӳٲ�ָ���PCֵ������ǰ��ָ֧���PC+4
    wire [31:0] bd_pc;   //�ӳٲ�ָ��PCֵ
    assign bd_pc = pc + 3'b100;
    
    //��������ת
    wire        j_taken;
    wire [31:0] j_target;
    assign j_taken = inst_J | inst_JAL | inst_jr;
    //�Ĵ�����ת��ַΪrs_value,������תΪ{bd_pc[31:28],target,2'b00}
    assign j_target = inst_jr ? rs_value : {bd_pc[31:28],target,2'b00};

    //branchָ��
    wire rs_equql_rt;
    wire rs_ez;
    wire rs_ltz;
    assign rs_equql_rt = (rs_value == rt_value);  // GPR[rs]==GPR[rt]
    assign rs_ez       = ~(|rs_value);            // rs�Ĵ���ֵΪ0
    assign rs_ltz      = rs_value[31];            // rs�Ĵ���ֵС��0
    wire br_taken;
    wire [31:0] br_target;
    assign br_taken = inst_BEQ  & rs_equql_rt       // �����ת
                    | inst_BNE  & ~rs_equql_rt      // ������ת
                    | inst_BGEZ & ~rs_ltz           // ���ڵ���0��ת
                    | inst_BGTZ & ~rs_ltz & ~rs_ez  // ����0��ת
                    | inst_BLEZ & (rs_ltz | rs_ez)  // С�ڵ���0��ת
                    | inst_BLTZ & rs_ltz;           // С��0��ת
    // ��֧��תĿ���ַ��PC=PC+offset<<2
    assign br_target[31:2] = bd_pc[31:2] + {{14{offset[15]}}, offset};  
    assign br_target[1:0]  = bd_pc[1:0];
    
    //jump and branchָ��
    wire jbr_taken;
    wire [31:0] jbr_target;
    assign jbr_taken = (j_taken | br_taken) & ID_over; 
    assign jbr_target = j_taken ? j_target : br_target;
    
    //ID��IF����ת����
    assign jbr_bus = {jbr_taken, jbr_target};
//-----{��ָ֧��ִ��}end

//-----{IDִ�����}begin
    //��������ˮ�ģ������������

// 以下为阻塞方式
//    wire rs_wait;
//    wire rt_wait;
//    assign rs_wait = ~inst_no_rs & (rs!=5'd0)
//                   & ( (rs==EXE_wdest) | (rs==MEM_wdest) | (rs==WB_wdest) );
                     
//    assign rt_wait = ~inst_no_rt & (rt!=5'd0)
//                   & ( (rt==EXE_wdest) | (rt==MEM_wdest) | (rt==WB_wdest) );
    
//    ���ڷ�֧��תָ�ֻ����IFִ����ɺ󣬲ſ�����ID��ɣ�
//    ����ID��������ˣ���IF����ȡָ���next_pc�������浽PC��ȥ��
//    ��ô��IF��ɣ�next_pc�����浽PC��ȥʱ��jbr_bus�ϵ������ѱ����Ч��
//    ���·�֧��תʧ��
//    (~inst_jbr | IF_over)����(~inst_jbr | (inst_jbr & IF_over))
//    assign ID_over = ID_valid & ~rs_wait & ~rt_wait & (~inst_jbr | IF_over);
        assign ID_over = ID_valid & (~inst_jbr | IF_over);
//-----{IDִ�����}end




//-----{ID->EXE����}begin
    //EXE��Ҫ�õ�����Ϣ
    wire multiply;         //�˷�MULT
    wire mthi;             //MTHI
    wire mtlo;             //MTLO
    assign multiply = inst_MULT;
    assign mthi     = inst_MTHI;
    assign mtlo     = inst_MTLO;
    //ALU����Դ�������Ϳ����ź�
    wire [11:0] alu_control;
    wire [31:0] alu_operand1;
    wire [31:0] alu_operand2;
    
    //��ν������ת�ǽ���ת���ص�PCֵ��ŵ�31�żĴ�����
    //����ˮCPU������ӳٲۣ���������ת��Ҫ����PC+8����ŵ�31�żĴ�����
    assign alu_operand1 = inst_j_link ? pc : 
                          inst_shf_sa ? {27'd0,sa} : rs_value;
    assign alu_operand2 = inst_j_link ? 32'd8 :  
                          inst_imm_zero ? {16'd0, imm} :
                          inst_imm_sign ?  {{16{imm[15]}}, imm} : rt_value;
    assign alu_control = {inst_add,        // ALU�����룬���ȱ���
                          inst_sub,
                          inst_slt,
                          inst_sltu,
                          inst_and,
                          inst_nor,
                          inst_or, 
                          inst_xor,
                          inst_sll,
                          inst_srl,
                          inst_sra,
                          inst_lui};
    //�ô���Ҫ�õ���load/store��Ϣ
    wire lb_sign;  //loadһ�ֽ�Ϊ�з���load
    wire ls_word;  //load/storeΪ�ֽڻ�����,0:byte;1:word
    wire [3:0] mem_control;  //MEM��Ҫʹ�õĿ����ź�
    wire [31:0] store_data;  //store�����Ĵ������
    assign lb_sign = inst_LB;
    assign ls_word = inst_LW | inst_SW;
    assign mem_control = {inst_load,
                          inst_store,
                          ls_word,
                          lb_sign };
                          
    //д����Ҫ�õ�����Ϣ
    wire mfhi;
    wire mflo;
    wire mtc0;
    wire mfc0;
    wire [7 :0] cp0r_addr;
    wire       syscall;   //syscall��eret��д�ؼ�������Ĳ��� 
    wire       eret;
    wire       rf_wen;    //д�صļĴ���дʹ��
    wire [4:0] rf_wdest;  //д�ص�Ŀ�ļĴ���
    assign syscall  = inst_SYSCALL;
    assign eret     = inst_ERET;
    assign mfhi     = inst_MFHI;
    assign mflo     = inst_MFLO;
    assign mtc0     = inst_MTC0;
    assign mfc0     = inst_MFC0;
    assign cp0r_addr= {rd,cp0r_sel};
    assign rf_wen   = inst_wdest_rt | inst_wdest_31 | inst_wdest_rd;
    assign rf_wdest = inst_wdest_rt ? rt :     //�ڲ�д�Ĵ�����ʱ����Ϊ0
                      inst_wdest_31 ? 5'd31 :  //�Ա���׼ȷ�ж��������
                      inst_wdest_rd ? rd : 5'd0;
    assign store_data = rt_value;
    assign ID_EXE_bus = {multiply,mthi,mtlo,                   //EXE���õ���Ϣ,����
                         alu_control,alu_operand1,alu_operand2,//EXE���õ���Ϣ
                         mem_control,store_data,               //MEM���õ��ź�
                         mfhi,mflo,                            //WB���õ��ź�,����
                         mtc0,mfc0,cp0r_addr,syscall,eret,     //WB���õ��ź�,����
                         rf_wen, rf_wdest,                     //WB���õ��ź�
                         pc};                                  //PCֵ
//-----{ID->EXE����}end

endmodule
