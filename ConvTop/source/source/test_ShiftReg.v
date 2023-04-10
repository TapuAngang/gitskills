/*检查移位寄存器ip核的功能，测试时使用7周期的深度，64位数据*/
`timescale 1ns / 1ps
`define CLK_PRD 10
`define CLK_HALF (`CLK_PRD / 2)

module test_ShiftReg();
    parameter DataWidth = 64;

    reg                      Clk;
    reg                      Rst;
    reg [DataWidth-1: 0]     din;
    reg [8:0]                addr;

    wire [DataWidth-1: 0]    dout;

    ShiftReg413 the_instance_name (
        .din(din),      // input [63:0]
        .clk(Clk),      // input
        .addr(addr),
        .rst(Rst),      // input
        .dout(dout)     // output [63:0]
    );

    initial begin
        Rst <= 1;

        #(2*`CLK_PRD);
        Rst <= 0;
    end

    initial begin
        addr <= 7;
        #(14*`CLK_PRD);
        addr <= 3;
    end

    integer i;
    initial begin
        din <= 0;
        #(4*`CLK_PRD);
        
        for (i = 0; i < 25; i = i + 1) begin
            din <= i;
            #(`CLK_PRD);
        end

    end

    always begin
        Clk = 1;
        #(`CLK_HALF);
        Clk = 0;
        #(`CLK_HALF);
    end

    always begin
        #(1);
        if ($time >= 40*`CLK_PRD)
            $finish;
    end


endmodule