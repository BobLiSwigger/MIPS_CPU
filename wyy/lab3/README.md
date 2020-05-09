## Let's create a CPU
目前完成的工作

借助龙芯实验指导书的五级流水代码

#### lab3-1

主要做的是更改接口，将龙芯的代码迁移到国科大上

然后配置调试的环境，具体附录里有

龙芯的cpu结构ram和rom在cpu内部，感觉像那个冯诺伊曼结构

国科大的cpu ram和rom是在外部的，所以接口不一样要改

#### lab3-2(有bug)

基本不需要做什么，因为在龙芯的那个里面实现了数据相关的处理，使用的是阻塞流水方式

```verilog
//decode.v

// 以下为阻塞方式
    wire rs_wait;
    wire rt_wait;
    assign rs_wait = ~inst_no_rs & (rs!=5'd0)
                   & ( (rs==EXE_wdest) | (rs==MEM_wdest) | (rs==WB_wdest) );
                     
    assign rt_wait = ~inst_no_rt & (rt!=5'd0)
                   & ( (rt==EXE_wdest) | (rt==MEM_wdest) | (rt==WB_wdest) );
    
//    ���ڷ�֧��תָ�ֻ����IFִ����ɺ󣬲ſ�����ID��ɣ�
//    ����ID��������ˣ���IF����ȡָ���next_pc�������浽PC��ȥ��
//    ��ô��IF��ɣ�next_pc�����浽PC��ȥʱ��jbr_bus�ϵ������ѱ����Ч��
//    ���·�֧��תʧ��
//    (~inst_jbr | IF_over)����(~inst_jbr | (inst_jbr & IF_over))
    assign ID_over = ID_valid & ~rs_wait & ~rt_wait & (~inst_jbr | IF_over);
```

不知道为什么原文件里的注释都变成了乱码，伤心

突然发现lab3-2需要自己实现ADDI，ADD，SUB这三条指令

#### lab3-3

要实现数据相关前递处理，主要就是ID阶段存在这个问题，加几个接口判断下就行

我将在MEM和EXE阶段的数据相关处理在decode.v中处理了

```verilog
// 接口的改成了rs_value_in & rt_value_in    

	wire [31:0] rs_value;
    wire [31:0] rt_value;

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
```

写回级的数据相关在regfile.v中处理(董老师好像不是很赞同改regfile)，顺便把regfile的代码改了一下，原来的太繁琐了

```verilog
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

    );
    reg [31:0] rf[31:0];
    assign debug_wb_rf_wen = {4{wen}};
    assign debug_wb_rf_wdata = wdata;
    assign debug_wb_rf_wnum = waddr;
     


    always @(posedge clk)
    begin
        if (wen) 
        begin
            rf[waddr] <= wdata;
        end
    end
     
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
    end
endmodule

```

接下来要做的是乘除法(数据前推还没有调试emm)

