`timescale 1ns / 1ps
//*************************************************************************
//   > �ļ���: regfile.v
//   > ����  ���Ĵ�����ģ�飬ͬ��д���첽��
//   > ����  : LOONGSON
//   > ����  : 2016-04-14
//*************************************************************************
module regfile(
    input             clk,
    input             wen,
    input      [4 :0] raddr1,
    input      [4 :0] raddr2,
    input      [4 :0] waddr,
    input      [31:0] wdata,
    output reg [31:0] rdata1,
    output reg [31:0] rdata2,

    output [3:0]debug_wb_rf_wen,
    output [4:0]debug_wb_rf_wnum,
    output [31:0]debug_wb_rf_wdata
//    input      [  4:0] EXE_wdest,   // EXE��Ҫд�ؼĴ����ѵ�Ŀ���ַ��
//    input      [  4:0] MEM_wdest,   // MEM��Ҫд�ؼĴ����ѵ�Ŀ���ַ��
//    input              EXE_wen,
//    input      [ 31:0] EXE_wdata,
//    input              MEM_wen,
//    input      [ 31:0] MEM_wdata,
//    input      [  4:0] WB_wdest     
    );
    reg [31:0] rf[31:0];
    assign debug_wb_rf_wen = {4{wen}};
    assign debug_wb_rf_wdata = wdata;
    assign debug_wb_rf_wnum = waddr;
     
    // three ported register file
    // read two ports combinationally
    // write third port on rising edge of clock
    // register 0 hardwired to 0

    always @(posedge clk)
    begin
        if (wen) 
        begin
            rf[waddr] <= wdata;
        end
    end
     
    //���˿�1
    
// 前递
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
    always @(*)
    begin
        if (wen && raddr1 == waddr)
        begin
            rdata1 <= wdata;
        end
        else if(raddr1 >= 5'd1 && raddr1 <= 5'd31)
        begin
            rdata1 <= rf[raddr1];
        end
        else
        begin
            rdata1 <= 32'b0;
        end
    
//        case (raddr1)
//            5'd1 : rdata1 <= rf[1 ];
//            5'd2 : rdata1 <= rf[2 ];
//            5'd3 : rdata1 <= rf[3 ];
//            5'd4 : rdata1 <= rf[4 ];
//            5'd5 : rdata1 <= rf[5 ];
//            5'd6 : rdata1 <= rf[6 ];
//            5'd7 : rdata1 <= rf[7 ];
//            5'd8 : rdata1 <= rf[8 ];
//            5'd9 : rdata1 <= rf[9 ];
//            5'd10: rdata1 <= rf[10];
//            5'd11: rdata1 <= rf[11];
//            5'd12: rdata1 <= rf[12];
//            5'd13: rdata1 <= rf[13];
//            5'd14: rdata1 <= rf[14];
//            5'd15: rdata1 <= rf[15];
//            5'd16: rdata1 <= rf[16];
//            5'd17: rdata1 <= rf[17];
//            5'd18: rdata1 <= rf[18];
//            5'd19: rdata1 <= rf[19];
//            5'd20: rdata1 <= rf[20];
//            5'd21: rdata1 <= rf[21];
//            5'd22: rdata1 <= rf[22];
//            5'd23: rdata1 <= rf[23];
//            5'd24: rdata1 <= rf[24];
//            5'd25: rdata1 <= rf[25];
//            5'd26: rdata1 <= rf[26];
//            5'd27: rdata1 <= rf[27];
//            5'd28: rdata1 <= rf[28];
//            5'd29: rdata1 <= rf[29];
//            5'd30: rdata1 <= rf[30];
//            5'd31: rdata1 <= rf[31];
//            default : rdata1 <= 32'd0;
//        endcase
    end
    //���˿�2
    always @(*)
    begin
        if (wen && raddr2 == waddr)
        begin
            rdata2 <= wdata;
        end
        else if(raddr2 >= 5'd1 && raddr2 <= 5'd31)
        begin
            rdata2 <= rf[raddr2];
        end
        else
        begin
            rdata2 <= 32'b0;
        end
//        case (raddr2)
//            5'd1 : rdata2 <= rf[1 ];
//            5'd2 : rdata2 <= rf[2 ];
//            5'd3 : rdata2 <= rf[3 ];
//            5'd4 : rdata2 <= rf[4 ];
//            5'd5 : rdata2 <= rf[5 ];
//            5'd6 : rdata2 <= rf[6 ];
//            5'd7 : rdata2 <= rf[7 ];
//            5'd8 : rdata2 <= rf[8 ];
//            5'd9 : rdata2 <= rf[9 ];
//            5'd10: rdata2 <= rf[10];
//            5'd11: rdata2 <= rf[11];
//            5'd12: rdata2 <= rf[12];
//            5'd13: rdata2 <= rf[13];
//            5'd14: rdata2 <= rf[14];
//            5'd15: rdata2 <= rf[15];
//            5'd16: rdata2 <= rf[16];
//            5'd17: rdata2 <= rf[17];
//            5'd18: rdata2 <= rf[18];
//            5'd19: rdata2 <= rf[19];
//            5'd20: rdata2 <= rf[20];
//            5'd21: rdata2 <= rf[21];
//            5'd22: rdata2 <= rf[22];
//            5'd23: rdata2 <= rf[23];
//            5'd24: rdata2 <= rf[24];
//            5'd25: rdata2 <= rf[25];
//            5'd26: rdata2 <= rf[26];
//            5'd27: rdata2 <= rf[27];
//            5'd28: rdata2 <= rf[28];
//            5'd29: rdata2 <= rf[29];
//            5'd30: rdata2 <= rf[30];
//            5'd31: rdata2 <= rf[31];
//            default : rdata2 <= 32'd0;
//        endcase
    end
endmodule
