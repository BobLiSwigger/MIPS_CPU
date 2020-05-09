`timescale 1ns / 1ps
//*************************************************************************
//   > �ļ���: wb.v
//   > ����  :�弶��ˮCPU��д��ģ��
//   > ����  : LOONGSON
//   > ����  : 2016-04-14
//*************************************************************************
`define EXC_ENTER_ADDR 32'd0     // Excption��ڵ�ַ��
                                 // �˴�ʵ�ֵ�Exceptionֻ��SYSCALL
module wb(                       // д�ؼ�
    input          WB_valid,     // д�ؼ���Ч
    input  [117:0] MEM_WB_bus_r, // MEM->WB����
    output         rf_wen,       // �Ĵ���дʹ��
    output [  4:0] rf_wdest,     // �Ĵ���д��ַ
    output [ 31:0] rf_wdata,     // �Ĵ���д����
    output         WB_over,      // WBģ��ִ�����

     //5����ˮ�����ӿ�
     input             clk,       // ʱ��
    input             resetn,    // ��λ�źţ��͵�ƽ��Ч
     output [ 32:0] exc_bus,      // Exception pc����
//     output [  4:0] WB_wdest,     // WB��Ҫд�ؼĴ����ѵ�Ŀ���ַ��
     output         cancel,       // syscall��eret����д�ؼ�ʱ�ᷢ��cancel�źţ�
                                  // ȡ���Ѿ�ȡ��������������ˮ��ִ�е�ָ��
 
     //չʾPC��HI/LOֵ
     output [ 31:0] WB_pc,
     output [ 31:0] HI_data,
     output [ 31:0] LO_data
);
//-----{MEM->WB����}begin    
    //MEM������result
    wire [31:0] mem_result;
    //HI/LO����
    wire [31:0] lo_result;
    wire        hi_write;
    wire        lo_write;
    
    //�Ĵ�����дʹ�ܺ�д��ַ
    wire wen;
    wire [4:0] wdest;
    
    //д����Ҫ�õ�����Ϣ
    wire mfhi;
    wire mflo;
    wire mtc0;
    wire mfc0;
    wire [7 :0] cp0r_addr;
    wire       syscall;   //syscall��eret��д�ؼ�������Ĳ��� 
    wire       eret;
    
    //pc
    wire [31:0] pc;    
    assign {wen,
            wdest,
            mem_result,
            lo_result,
            hi_write,
            lo_write,
            mfhi,
            mflo,
            mtc0,
            mfc0,
            cp0r_addr,
            syscall,
            eret,
            pc} = MEM_WB_bus_r;
//-----{MEM->WB����}end

//-----{HI/LO�Ĵ���}begin
    //HI���ڴ�ų˷�����ĸ�32λ
    //LO���ڴ�ų˷�����ĵ�32λ
    reg [31:0] hi;
    reg [31:0] lo;
    
    //Ҫд��HI�����ݴ����mem_result��
    always @(posedge clk)
    begin
        if (hi_write)
        begin
            hi <= mem_result;
        end
    end
    //Ҫд��LO�����ݴ����lo_result��
    always @(posedge clk)
    begin
        if (lo_write)
        begin
            lo <= lo_result;
        end
    end
//-----{HI/LO�Ĵ���}end

//-----{cp0�Ĵ���}begin
// cp0�Ĵ�������Э������0�Ĵ���
// ����Ŀǰ��Ƶ�CPU�����걸�����õ���cp0�Ĵ���Ҳ����
// ����ʱֻʵ��STATUS(12.0),CAUSE(13.0),EPC(14.0)������
// ÿ��CP0�Ĵ�������ʹ��5λ��cp0��
   wire [31:0] cp0r_status;
   wire [31:0] cp0r_cause;
   wire [31:0] cp0r_epc;
   
   //дʹ��
   wire status_wen;
   //wire cause_wen;
   wire epc_wen;
   assign status_wen = mtc0 & (cp0r_addr=={5'd12,3'd0});
   assign epc_wen    = mtc0 & (cp0r_addr=={5'd14,3'd0});
   
   //cp0�Ĵ�����
   wire [31:0] cp0r_rdata;
   assign cp0r_rdata = (cp0r_addr=={5'd12,3'd0}) ? cp0r_status :
                       (cp0r_addr=={5'd13,3'd0}) ? cp0r_cause  :
                       (cp0r_addr=={5'd14,3'd0}) ? cp0r_epc : 32'd0;
   
   //STATUS�Ĵ���
   //Ŀǰֻʵ��STATUS[1]λ����EXL��
   //EXL��Ϊ����ɶ�д������Ҫstatu_wen
   reg status_exl_r;
   assign cp0r_status = {30'd0,status_exl_r,1'b0};
   always @(posedge clk)
   begin
       if (!resetn || eret)
       begin
           status_exl_r <= 1'b0;
       end
       else if (syscall)
       begin
           status_exl_r <= 1'b1;
       end
       else if (status_wen)
       begin
           status_exl_r <= mem_result[1];
       end
   end
   
   //CAUSE�Ĵ���
   //Ŀǰֻʵ��CAUSE[6:2]λ����ExcCode��,���Exception����
   //ExcCode��Ϊ���ֻ��������д���ʲ���Ҫcause_wen
   reg [4:0] cause_exc_code_r;
   assign cp0r_cause = {25'd0,cause_exc_code_r,2'd0};
   always @(posedge clk)
   begin
       if (syscall)
       begin
           cause_exc_code_r <= 5'd8;
       end
   end
   
   //EPC�Ĵ���
   //��Ų�������ĵ�ַ
   //EPC������Ϊ����ɶ�д�ģ�����Ҫepc_wen
   reg [31:0] epc_r;
   assign cp0r_epc = epc_r;
   always @(posedge clk)
   begin
       if (syscall)
       begin
           epc_r <= pc;
       end
       else if (epc_wen)
       begin
           epc_r <= mem_result;
       end
   end
   
   //syscall��eret������cancel�ź�
   assign cancel = (syscall | eret) & WB_over;
//-----{cp0�Ĵ���}begin

//-----{WBִ�����}begin
    //WBģ�����в���������һ�������
    //��WB_valid����WB_over�ź�
    assign WB_over = WB_valid;
//-----{WBִ�����}end

//-----{WB->regfile�ź�}begin
    assign rf_wen   = wen & WB_over;
    assign rf_wdest = wdest;
    assign rf_wdata = mfhi ? hi :
                      mflo ? lo :
                      mfc0 ? cp0r_rdata : mem_result;
//-----{WB->regfile�ź�}end

//-----{Exception pc�ź�}begin
    wire        exc_valid;
    wire [31:0] exc_pc;
    assign exc_valid = (syscall | eret) & WB_valid;
    //eret���ص�ַΪEPC�Ĵ�����ֵ
    //SYSCALL��excPCӦ��Ϊ{EBASE[31:10],10'h180},
    //����Ϊʵ�飬������EXC_ENTER_ADDRΪ0��������Գ���ı�д
    assign exc_pc = syscall ? `EXC_ENTER_ADDR : cp0r_epc;
    
    assign exc_bus = {exc_valid,exc_pc};
//-----{Exception pc�ź�}end

//-----{WBģ���destֵ}begin
   //ֻ����WBģ����Чʱ����д��Ŀ�ļĴ����Ų�������
//    assign WB_wdest = rf_wdest & {5{WB_valid}};
//-----{WBģ���destֵ}end

//-----{չʾWBģ���PCֵ��HI/LO�Ĵ�����ֵ}begin
    assign WB_pc = pc;
    assign HI_data = hi;
    assign LO_data = lo;
//-----{չʾWBģ���PCֵ��HI/LO�Ĵ�����ֵ}end
endmodule

