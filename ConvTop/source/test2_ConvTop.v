/*
    ConvTop仿真
    采用8*8*4（PictureSize*PictureSize*4）的原始图像，padding自然为1
    利用伪随机数，再次验证卷积运算的正确性
*/
`timescale 1ns / 100ps
`define CLK_PRD 10
`define CLK_HALF (`CLK_PRD / 2)

module test2_ConvTop();
    parameter PictureSize = 8;
    parameter DataWidth = 64;
    parameter KernelSize = 9;

    reg                     Clk;
    reg                     Rst;
    reg [8:0]               row_in;
    reg [8:0]               col_in;

    reg [4*DataWidth-1: 0]  weight_in;
    reg                     weight_valid;

    reg [4*DataWidth-1: 0]  data_in;
    reg                     data_valid;

    wire [DataWidth-1: 0]   result_out;
    wire                    result_ready;

    ConvTop #(.DataWidth(DataWidth), .KernelSize(KernelSize))
    UConvTop
    (
        .Clk            (Clk),
        .Rst            (Rst),
        .row_in         (row_in),
        .col_in         (col_in),

        .weight_in      (weight_in),
        .weight_valid   (weight_valid),

        .data_in        (data_in),
        .data_valid     (data_valid),

        .result_out     (result_out),
        .result_ready   (result_ready)
    );

    initial begin
        Rst <= 1;
        row_in <= PictureSize;
        col_in <= PictureSize;

        #(2*`CLK_PRD);
        Rst <= 0;
    end

    integer i, j;
    integer data4, data3, data2, data1;
    initial begin
        weight_valid <= 0;
        weight_in <= 0;
        data_valid <= 0;
        data_in <= 0;

        //录入权重
        #(5*`CLK_PRD);
        weight_valid <= 1;
                    //4      3      2      1
        weight_in[0 +: 64] <= $random % 10;     //weight11
        weight_in[64 +: 64] <= $random % 10;
        weight_in[2*64 +: 64] <= $random % 10;
        weight_in[3*64 +: 64] <= $random % 10;

        #(`CLK_PRD);
        weight_in[0 +: 64] <= $random % 10;
        weight_in[64 +: 64] <= $random % 10;
        weight_in[2*64 +: 64] <= $random % 10;
        weight_in[3*64 +: 64] <= $random % 10;

        #(`CLK_PRD);
        weight_in[0 +: 64] <= $random % 10;
        weight_in[64 +: 64] <= $random % 10;
        weight_in[2*64 +: 64] <= $random % 10;
        weight_in[3*64 +: 64] <= $random % 10;

        #(`CLK_PRD);
        weight_in[0 +: 64] <= $random % 10;     //weight21
        weight_in[64 +: 64] <= $random % 10;
        weight_in[2*64 +: 64] <= $random % 10;
        weight_in[3*64 +: 64] <= $random % 10;

        #(`CLK_PRD);
        weight_in[0 +: 64] <= $random % 10;
        weight_in[64 +: 64] <= $random % 10;
        weight_in[2*64 +: 64] <= $random % 10;
        weight_in[3*64 +: 64] <= $random % 10;

        #(`CLK_PRD);
        weight_in[0 +: 64] <= $random % 10;
        weight_in[64 +: 64] <= $random % 10;
        weight_in[2*64 +: 64] <= $random % 10;
        weight_in[3*64 +: 64] <= $random % 10;

        #(`CLK_PRD);
        weight_in[0 +: 64] <= $random % 10;     //weight31
        weight_in[64 +: 64] <= $random % 10;
        weight_in[2*64 +: 64] <= $random % 10;
        weight_in[3*64 +: 64] <= $random % 10;

        #(`CLK_PRD);
        weight_in[0 +: 64] <= $random % 10;     //weight21
        weight_in[64 +: 64] <= $random % 10;
        weight_in[2*64 +: 64] <= $random % 10;
        weight_in[3*64 +: 64] <= $random % 10;

        #(`CLK_PRD);
        weight_in[0 +: 64] <= $random % 10;     //weight21
        weight_in[64 +: 64] <= $random % 10;
        weight_in[2*64 +: 64] <= $random % 10;
        weight_in[3*64 +: 64] <= $random % 10;

        #(`CLK_PRD);
        weight_valid <= 0;
        weight_in <= 0;

        //录入数据
        #(4*`CLK_PRD);
        data_valid <= 1;

        for (i = 1; i <= PictureSize; i = i + 1) begin
            for (j = 1; j <= PictureSize; j = j + 1) begin
                data1 = $random % 100;
                data2 = $random % 100;
                data3 = $random % 100;
                data4 = $random % 100;

                data_in[3*64 +: 64] <= data4;
                data_in[2*64 +: 64] <= data3;
                data_in[64 +: 64] <= data2;
                data_in[0 +: 64] <= data1;
                #(`CLK_PRD);
            end
        end

        data_valid <= 0;
        data_in <= 0;
    end

    always begin
        Clk = 1;
        #(`CLK_HALF);
        Clk = 0;
        #(`CLK_HALF);
    end

    //权重输出
    integer wcount = 0;
    integer wp1, wp2, wp3, wp4;
    integer weight1, weight2, weight3, weight4;
    always begin
        #(`CLK_HALF);
        if (weight_valid && ~Rst) begin
            wcount = wcount + 1;

            //将线网变量转化为有符号整数，一个方法是借助integer
            weight1 = weight_in[0 +: 64];
            weight2 = weight_in[64 +: 64];
            weight3 = weight_in[2*64 +: 64];
            weight4 = weight_in[3*64 +: 64];
            
            wp1 = $fopen("data/weight1.txt", "a");
            wp2 = $fopen("data/weight2.txt", "a");
            wp3 = $fopen("data/weight3.txt", "a");
            wp4 = $fopen("data/weight4.txt", "a");

            $fwrite(wp1, "%d%s", weight1, (wcount % 3)? ", " : ";\n");
            $fwrite(wp2, "%d%s", weight2, (wcount % 3)? ", " : ";\n");
            $fwrite(wp3, "%d%s", weight3, (wcount % 3)? ", " : ";\n");
            $fwrite(wp4, "%d%s", weight4, (wcount % 3)? ", " : ";\n");

            $fclose(wp1);
            $fclose(wp2);
            $fclose(wp3);
            $fclose(wp4);
        end
        #(`CLK_HALF);
    end

    //数据输出
    integer dp1, dp2, dp3, dp4;
    always begin
        #(`CLK_HALF);
        if (data_valid && ~Rst) begin
            dp1 = $fopen("data/data1.txt", "a");
            dp2 = $fopen("data/data2.txt", "a");
            dp3 = $fopen("data/data3.txt", "a");
            dp4 = $fopen("data/data4.txt", "a");

            $fwrite(dp1, "%d%s", data1, (j < PictureSize)? ", " : ";\n");
            $fwrite(dp2, "%d%s", data2, (j < PictureSize)? ", " : ";\n");
            $fwrite(dp3, "%d%s", data3, (j < PictureSize)? ", " : ";\n");
            $fwrite(dp4, "%d%s", data4, (j < PictureSize)? ", " : ";\n");

            $fclose(dp1);
            $fclose(dp2);
            $fclose(dp3);
            $fclose(dp4);
        end
        #(`CLK_HALF);
    end

    //结果输出
    integer rcount = 0;
    integer rp;
    integer result_signed;
    always begin
        #(`CLK_HALF);
        if (result_ready && ~Rst) begin
            rcount = rcount + 1;
            result_signed = result_out;
            
            rp = $fopen("data/result.txt", "a");

            $fwrite(rp, "%d%s", result_signed, (rcount % PictureSize)? ", " : ";\n");

            $fclose(rp);
        end
        #(`CLK_HALF);
    end

    always begin
        #(1);
        if ($stime >= 100*`CLK_PRD)
            $finish;
    end


endmodule