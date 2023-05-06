/*
    ConvAccum仿真
    验证conv_first功能以及RAM存储功能
*/
`timescale 1ns / 100ps
`define CLK_PRD 10
`define CLK_HALF (`CLK_PRD / 2)

module test_ConvAccum_store();
    parameter PictureSize = 6;
    parameter DataWidth = 32;
    parameter KernelSize = 9;
    parameter AddrWidth = 16;
    parameter MaxPictWidth = 9;

    reg                     Clk;
    reg                     Rst;
    reg [8:0]               row_in;
    reg [8:0]               col_in;
    reg                     conv_first;

    reg [4*DataWidth-1: 0]  weight_in;
    reg                     weight_valid;

    reg [4*DataWidth-1: 0]  data_in;
    reg [MaxPictWidth-1: 0] col_count;
    reg [MaxPictWidth-1: 0] row_count;

    wire [DataWidth-1: 0]   rd_data_conv;
    wire [AddrWidth-1: 0]   rd_addr_conv;

    wire [AddrWidth-1: 0]   wr_addr_conv;
    wire [DataWidth-1: 0]   wr_data_conv;
    wire                    wr_en_conv;

    reg                     data_valid;         //辅助变量，用于判断数据是否有效

    ConvAccum #(.DataWidth(DataWidth), .KernelSize(KernelSize))
    UConvAccum
    (
        .Clk            (Clk),
        .Rst            (Rst),
        .row_in         (row_in),
        .col_in         (col_in),
        .conv_first     (conv_first),

        .weight_in      (weight_in),
        .weight_valid   (weight_valid),

        .data_in        (data_in),
        .col_count      (col_count),
        .row_count      (row_count),

        .rd_addr_conv   (rd_addr_conv),
        .rd_data_conv   (rd_data_conv),

        .wr_addr_conv   (wr_addr_conv),
        .wr_data_conv   (wr_data_conv),
        .wr_en_conv     (wr_en_conv)
    );

    //使能输出寄存器，地址位仅有10位
    DisRAM UDisRAM (
        .wr_data    (wr_data_conv),         // input [31:0]
        .wr_addr    (wr_addr_conv[9:0]),    // input [9:0]
        .wr_en      (wr_en_conv),           // input
        .wr_clk     (Clk),                  // input
        .rd_addr    (rd_addr_conv[9:0]),    // input [9:0]
        .rd_data    (rd_data_conv),         // output [31:0]
        .rd_clk     (Clk),                  // input
        .rst        (Rst)                   // input
        );

    //复位/行列数信号控制--------------------------------------------------------
    initial begin
        Rst <= 1;
        row_in <= PictureSize;
        col_in <= PictureSize;
        conv_first <= 1;
        data_valid <= 0;

        #(2*`CLK_PRD);
        Rst <= 0;

        #(70*`CLK_PRD);
        Rst <= 1;
        conv_first <= 0;

        #(2*`CLK_PRD);
        Rst <= 0;
    end

    //权重/数据输入--------------------------------------------------------------
    integer i, j, k;
    initial begin
        weight_valid <= 0;
        weight_in <= 0;
        data_in <= 0;
        col_count <= 0;
        row_count <= 0;

        //录入权重
        #(5*`CLK_PRD);
        weight_valid <= 1;
        for (k = 0; k < KernelSize; k = k + 1) begin
            weight_in[0 +: 32] <= $random % 10;
            weight_in[32 +: 32] <= $random % 10;
            weight_in[2*32 +: 32] <= $random % 10;
            weight_in[3*32 +: 32] <= $random % 10;

            #(`CLK_PRD);
        end

        weight_valid <= 0;
        weight_in <= 0;

        //录入数据
        #(4*`CLK_PRD);
        data_valid <= 1;

        for (i = 1; i <= PictureSize + 2; i = i + 1) begin
            row_count <= 0;
            for (j = 1; j <= PictureSize; j = j + 1) begin
                row_count <= (row_count + 1) % PictureSize;
                data_in[3*32 +: 32] <= $random % 100;
                data_in[2*32 +: 32] <= $random % 100;
                data_in[32 +: 32] <= $random % 100;
                data_in[0 +: 32] <= $random % 100;
                if (row_count == PictureSize - 1) begin
                    col_count <= col_count + 1;
                end
                #(`CLK_PRD);
            end
        end

        data_in <= 0;
        data_valid <= 0;
        col_count <= 0;
        row_count <= 0;

        //二次录入权重
        #(30*`CLK_PRD);
        weight_valid <= 1;
        for (k = 0; k < KernelSize; k = k + 1) begin
            weight_in[0 +: 32] <= $random % 10;
            weight_in[32 +: 32] <= $random % 10;
            weight_in[2*32 +: 32] <= $random % 10;
            weight_in[3*32 +: 32] <= $random % 10;

            #(`CLK_PRD);
        end

        weight_valid <= 0;
        weight_in <= 0;

        #(2*`CLK_PRD);
        //二次录入数据
        data_valid <= 1;
        for (i = 1; i <= PictureSize + 2; i = i + 1) begin
            row_count <= 0;
            for (j = 1; j <= PictureSize; j = j + 1) begin
                row_count <= (row_count + 1) % PictureSize;
                data_in[3*32 +: 32] <= $random % 100;
                data_in[2*32 +: 32] <= $random % 100;
                data_in[32 +: 32] <= $random % 100;
                data_in[0 +: 32] <= $random % 100;
                if (row_count == PictureSize - 1) begin
                    col_count <= col_count + 1;
                end
                #(`CLK_PRD);
            end
        end

        data_in <= 0;
        data_valid <= 0;
    end

    //数据输出--------------------------------------------------------------------------------
    //权重输出
    integer wcount = 0;                             //权重计数器
    integer wp1, wp2, wp3, wp4;                     //权重文件指针
    integer weight1, weight2, weight3, weight4;     //权重变量，用于转化为有符号整数
    always begin                                    //使用always块，每个周期检测权重有效信号
        #(`CLK_HALF);
        if (weight_valid && ~Rst) begin
            wcount = wcount + 1;

            //将线网变量转化为有符号整数，一个方法是借助integer
            weight1 = weight_in[0 +: 32];
            weight2 = weight_in[32 +: 32];
            weight3 = weight_in[2*32 +: 32];
            weight4 = weight_in[3*32 +: 32];
            
            wp1 = $fopen("data/weight1.txt", "a");  //路径为data文件夹下的weight1.txt
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
    integer data1, data2, data3, data4;
    always begin
        #(`CLK_HALF);
        if (data_valid && (col_count < PictureSize || col_count == PictureSize && row_count == 0) && ~Rst) begin
            data1 = data_in[0 +: 32];
            data2 = data_in[32 +: 32];
            data3 = data_in[2*32 +: 32];
            data4 = data_in[3*32 +: 32];

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
        if (wr_en_conv && ~Rst) begin
            rcount = rcount + 1;
            result_signed = wr_data_conv;
            
            rp = $fopen("data/result.txt", "a");

            $fwrite(rp, "%d%s", result_signed, (rcount % PictureSize)? ", " : ";\n");

            $fclose(rp);
        end
        #(`CLK_HALF);
    end

    //时钟与进程结束------------------------------------------------------------------------------
    always begin
        Clk = 1;
        #(`CLK_HALF);
        Clk = 0;
        #(`CLK_HALF);
    end
    
    always begin
        #(1);
        if ($stime >= 200*`CLK_PRD)
            $finish;
    end


endmodule