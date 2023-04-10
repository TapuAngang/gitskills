/*
    LineBuffer仿真
    采用7*7（PictureSize*PictureSize）的原始图像，padding自然为1
    输入数据的形式为：[63：32]位表示行数，[31:0]位表示列数，例如：第三行第八列为0x0000_0003_0000_0008
*/
`timescale 1ns / 1ps
`define CLK_PRD 10
`define CLK_HALF (`CLK_PRD / 2)

module test_LineBuffer();
    parameter DataWidth = 64, KernelSize = 9;
    parameter PictureSize = 7;

    reg                     Clk;
    reg                     Rst;
    reg [8:0]               row_in;
    reg [8:0]               col_in;

    reg [DataWidth-1: 0]    data_in;
    reg                     data_valid;

    wire [9*DataWidth-1: 0] window_out;
    wire                    window_valid;

    LineBuffer #(.DataWidth(DataWidth), .KernelSize(KernelSize))
    ULinebuffer
    (
        .Clk(Clk),
        .Rst(Rst),

        .row_in(row_in),
        .col_in(col_in),
        .data_in(data_in),
        .data_valid(data_valid),

        .window_out(window_out),
        .window_valid(window_valid)
    );

    initial begin
        Rst <= 1;
        row_in <= PictureSize;
        col_in <= PictureSize;

        #(2*`CLK_PRD);
        Rst <= 0;
    end

    integer i, j;
    initial begin
        data_valid <= 0;

        #(4*`CLK_PRD);
        data_valid <= 1;

        //依次流入49个数据
        for (i = 1; i <= PictureSize; i = i + 1) begin
            for (j = 1; j <= PictureSize; j = j + 1) begin
                data_in <= {i, j};
                #(`CLK_PRD);
            end
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
        if ($time >= 80*`CLK_PRD)
            $finish;
    end


endmodule