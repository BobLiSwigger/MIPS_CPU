`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/01 23:28:01
// Design Name: 
// Module Name: mycpu_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mycpu_top(
    input clk,
    input resetn,
    
    output inst_sram_en,
    output [3:0]inst_sram_wen,
    output [31:0]inst_sram_addr,
    output [31:0]inst_sram_wdata,
    input [31:0]inst_sram_rdata,
    
    output data_sram_en,
    output [3:0]data_sram_wen,
    output [31:0]data_sram_addr,
    output [31:0]data_sram_wdata,
    input  [31:0]data_sram_rdata,
    
    output [31:0]debug_wb_pc,
    output [3:0]debug_wb_rf_wen,
    output [4:0]debug_wb_rf_wnum,
    output [31:0]debug_wb_rf_wdata        
    );
    assign inst_sram_wen = 4'b0;
    assign inst_sram_wdata = 32'b0;
    assign inst_sram_en = 1'b1;
    
    assign data_sram_en = 1'b1;
    
    wire [31:0]IF_pc;
    wire [31:0]IF_inst;
    wire [31:0]ID_pc;
    wire [31:0]EXE_pc;
    wire [31:0]MEM_pc;
    wire [31:0] HI_data; //寄存器HI的值
    wire [31:0] LO_data; // 寄存器LO的值

    reg IF_valid;
    reg ID_valid;
    reg EXE_valid;
    reg MEM_valid;
    reg WB_valid;

    wire IF_over;
    wire ID_over;
    wire EXE_over;
    wire MEM_over;
    wire WB_over;

    wire IF_allow_in;
    wire ID_allow_in;
    wire EXE_allow_in;
    wire MEM_allow_in;
    wire WB_allow_in;
    

    wire cancel;    
    
    assign IF_allow_in  = (IF_over & ID_allow_in) | cancel;
    assign ID_allow_in  = ~ID_valid  | (ID_over  & EXE_allow_in);
    assign EXE_allow_in = ~EXE_valid | (EXE_over & MEM_allow_in);
    assign MEM_allow_in = ~MEM_valid | (MEM_over & WB_allow_in );
    assign WB_allow_in  = ~WB_valid  | WB_over;
   
    //IF_valid���ڸ�λ��һֱ��Ч
   always @(posedge clk)
    begin
        if (!resetn)
        begin
            IF_valid <= 1'b0;
        end
        else
        begin
            IF_valid <= 1'b1;
        end
    end
    
    //ID_valid
    always @(posedge clk)
    begin
        if (!resetn || cancel)
        begin
            ID_valid <= 1'b0;
        end
        else if (ID_allow_in)
        begin
            ID_valid <= IF_over;
        end
    end
    
    //EXE_valid
    always @(posedge clk)
    begin
        if (!resetn || cancel)
        begin
            EXE_valid <= 1'b0;
        end
        else if (EXE_allow_in)
        begin
            EXE_valid <= ID_over;
        end
    end
    
    //MEM_valid
    always @(posedge clk)
    begin
        if (!resetn || cancel)
        begin
            MEM_valid <= 1'b0;
        end
        else if (MEM_allow_in)
        begin
            MEM_valid <= EXE_over;
        end
    end
    
    //WB_valid
    always @(posedge clk)
    begin
        if (!resetn || cancel)
        begin
            WB_valid <= 1'b0;
        end
        else if (WB_allow_in)
        begin
            WB_valid <= MEM_over;
        end
    end
    
    //չʾ5����valid�ź�
//-------------------------{5����ˮ�����ź�}end--------------------------//

//--------------------------{5���������}begin---------------------------//
    wire [ 63:0] IF_ID_bus;   // IF->ID������
    wire [166:0] ID_EXE_bus;  // ID->EXE������
    wire [153:0] EXE_MEM_bus; // EXE->MEM������
    wire [117:0] MEM_WB_bus;  // MEM->WB������
    
    //�������������ź�
    reg [ 63:0] IF_ID_bus_r;
    reg [166:0] ID_EXE_bus_r;
    reg [153:0] EXE_MEM_bus_r;
    reg [117:0] MEM_WB_bus_r;
    
    //IF��ID�������ź�
    always @(posedge clk)
    begin
        if(IF_over && ID_allow_in)
        begin
            IF_ID_bus_r <= IF_ID_bus;
        end
    end
    //ID��EXE�������ź�
    always @(posedge clk)
    begin
        if(ID_over && EXE_allow_in)
        begin
            ID_EXE_bus_r <= ID_EXE_bus;
        end
    end
    //EXE��MEM�������ź�
    always @(posedge clk)
    begin
        if(EXE_over && MEM_allow_in)
        begin
            EXE_MEM_bus_r <= EXE_MEM_bus;
        end
    end    
    //MEM��WB�������ź�
    always @(posedge clk)
    begin
        if(MEM_over && WB_allow_in)
        begin
            MEM_WB_bus_r <= MEM_WB_bus;
        end
    end
//---------------------------{5���������}end----------------------------//

//--------------------------{���������ź�}begin--------------------------//
    //��ת����
    wire [ 32:0] jbr_bus;    


    //ID��EXE��MEM��WB����
    wire [ 4:0] EXE_wdest;
    wire [ 4:0] MEM_wdest;
    wire [31:0] EXE_wdata;
    wire [31:0] MEM_wdata;
    wire        EXE_wen;
    wire        MEM_wen;

//    wire [ 4:0] WB_wdest;
    

    //ID��regfile����
    wire [ 4:0] rs;
    wire [ 4:0] rt;   
    wire [31:0] rs_value;
    wire [31:0] rt_value;
    
    wire        rf_wen;
    wire [ 4:0] rf_wdest;
    wire [31:0] rf_wdata;
   
    
    //WB��IF��Ľ����ź�
    wire [32:0] exc_bus;
//---------------------------{���������ź�}end---------------------------//

//-------------------------{��ģ��ʵ����}begin---------------------------//
    wire next_fetch; //��������ȡָģ�飬��Ҫ������PCֵ
    //IF�������ʱ��������PCֵ��ȡ��һ��ָ��
    assign next_fetch = IF_allow_in;
    fetch IF_module(             // ȡָ��
        .clk       (clk       ),  // I, 1
        .resetn    (resetn    ),  // I, 1
        .IF_valid  (IF_valid  ),  // I, 1
        .next_fetch(next_fetch),  // I, 1
        .inst      (inst_sram_rdata      ),  // I, 32
        .jbr_bus   (jbr_bus   ),  // I, 33
        .inst_addr (inst_sram_addr ),  // O, 32
        .IF_over   (IF_over   ),  // O, 1
        .IF_ID_bus (IF_ID_bus ),  // O, 64
        
        //5����ˮ�����ӿ�
        .exc_bus   (exc_bus   )  // I, 32
    );

    decode ID_module(               // ���뼶
        .ID_valid   (ID_valid   ),  // I, 1
        .IF_ID_bus_r(IF_ID_bus_r),  // I, 64
        .rs_value_in   (rs_value   ),  // I, 32
        .rt_value_in   (rt_value   ),  // I, 32
        .rs         (rs         ),  // O, 5
        .rt         (rt         ),  // O, 5
        .jbr_bus    (jbr_bus    ),  // O, 33
//        .inst_jbr   (inst_jbr   ),  // O, 1
        .ID_over    (ID_over    ),  // O, 1
        .ID_EXE_bus (ID_EXE_bus ),  // O, 167
        
        //5����ˮ����
        .IF_over     (IF_over     ),// I, 1
        .EXE_wdest   (EXE_wdest   ),// I, 5
        .MEM_wdest   (MEM_wdest   ),// I, 5
        .EXE_wen     (EXE_wen),
        .EXE_wdata   (EXE_wdata),
        .MEM_wen     (MEM_wen),
        .MEM_wdata   (MEM_wdata),
        .WB_wdest    (WB_wdest    )// I, 5

    ); 

    exe EXE_module(                   // ִ�м�
        .EXE_valid   (EXE_valid   ),  // I, 1
        .ID_EXE_bus_r(ID_EXE_bus_r),  // I, 167
        .EXE_over    (EXE_over    ),  // O, 1 
        .EXE_MEM_bus (EXE_MEM_bus ),  // O, 154
        
        //5����ˮ����
        .clk         (clk         ),  // I, 1
        .EXE_wdest   (EXE_wdest   ), // O, 5
        .EXE_wen     (EXE_wen),
        .EXE_wdata   (EXE_wdata)

    );

    mem MEM_module(                     // �ô漶
        .clk          (clk          ),  // I, 1 
        .MEM_valid    (MEM_valid    ),  // I, 1
        .EXE_MEM_bus_r(EXE_MEM_bus_r),  // I, 154
        .dm_rdata     (data_sram_rdata     ),  // I, 32
        .dm_addr      (data_sram_addr      ),  // O, 32
        .dm_wen       (data_sram_wen       ),  // O, 4 
        .dm_wdata     (data_sram_wdata     ),  // O, 32
        .MEM_over     (MEM_over     ),  // O, 1
        .MEM_WB_bus   (MEM_WB_bus   ),  // O, 118
        
        //5����ˮ�����ӿ�
        .MEM_allow_in (MEM_allow_in ),  // I, 1
        .MEM_wdest    (MEM_wdest    ),  // O, 5
        .MEM_wen      (MEM_wen),
        .MEM_wdata    (MEM_wdata)
        
    );          
 
    wb WB_module(                     // д�ؼ�
        .WB_valid    (WB_valid    ),  // I, 1
        .MEM_WB_bus_r(MEM_WB_bus_r),  // I, 118
        .rf_wen      (rf_wen      ),  // O, 1
        .rf_wdest    (rf_wdest    ),  // O, 5
        .rf_wdata    (rf_wdata    ),  // O, 32
        .WB_over     (WB_over     ),  // O, 1
        

        .clk         (clk         ),  // I, 1
        .resetn      (resetn      ),  // I, 1
        .exc_bus     (exc_bus     ),  // O, 32
//        .WB_wdest    (WB_wdest    ),  // O, 5
        .cancel      (cancel      ),  // O, 1
        

        .WB_pc       (debug_wb_pc       ),  // O, 32
        .HI_data     (HI_data     ),  // O, 32
        .LO_data     (LO_data     )   // O, 32
    );

    regfile rf_module(
        .clk(clk),
        .wen(rf_wen),
        .raddr1(rs),
        .raddr2(rt),
        .waddr(rf_wdest),
        .wdata(rf_wdata),
        .rdata1(rs_value),
        .rdata2(rt_value),
        .debug_wb_rf_wen(debug_wb_rf_wen),
        .debug_wb_rf_wnum(debug_wb_rf_wnum),
        .debug_wb_rf_wdata(debug_wb_rf_wdata)
//        .EXE_wdest   (EXE_wdest   ),// I, 5
//        .MEM_wdest   (MEM_wdest   ),// I, 5
//        .EXE_wen     (EXE_wen),
//        .EXE_wdata   (EXE_wdata),
//        .MEM_wen     (MEM_wen),
//        .MEM_wdata   (MEM_wdata)
    );

    
endmodule
