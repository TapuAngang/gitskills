/*ConvChannel的testbench，测试时使用32位*/

`timescale 1ns / 1ps
`define CLK_PRD 10
`define CLK_HALF (`CLK_PRD / 2)

module test_ConvChannel();
   parameter DataWidth = 32;
   parameter KernelSize = 9;
   parameter InputDim = 4;

   reg                                      Clk;
   reg                                      Rst;
   reg [InputDim*DataWidth-1: 0]            weight_in;
   reg                                      weight_valid;
   reg [InputDim*KernelSize*DataWidth-1: 0] window_in;
   reg                                      window_valid;

   wire [DataWidth-1: 0]                    result_out;
   wire                                     result_ready;

    ConvChannel #(.DataWidth(DataWidth), .KernelSize(KernelSize))
        UConvChannel (
            .Clk            (Clk),
            .Rst            (Rst),
            .weight_in      (weight_in),
            .weight_valid   (weight_valid),
            .window_in      (window_in),
            .window_valid   (window_valid),

            .result_out     (result_out),
            .result_ready   (result_ready)
      );

    initial begin
        Rst <= 1;

        #(2*`CLK_PRD);
        Rst <= 0;

        #(23*`CLK_PRD);
        Rst <= 1;

        #(2*`CLK_PRD);
        Rst <= 0;
    end

    initial begin
        weight_valid <= 0;
        weight_in <= 32'd0;

        #(4*`CLK_PRD);
        weight_valid <= 1;
        weight_in <= {32'd2, 32'd4, 32'd1, 32'd1}; //1-1

        #(`CLK_PRD);
        weight_in <= {32'd2, 32'd3, 32'd0, $unsigned(-1)};

        #(`CLK_PRD);
        weight_in <= {32'd2, 32'd2, 32'd1, 32'd2};

        #(`CLK_PRD);
        weight_in <= {$unsigned(-2), 32'd1, 32'd0, 32'd1}; //2-1

        #(`CLK_PRD);
        weight_in <= {$unsigned(-2), 32'd0, 32'd1, $unsigned(-1)};

        #(`CLK_PRD);
        weight_in <= {$unsigned(-2), $unsigned(-1), 32'd0, 32'd2};

        #(`CLK_PRD);
        weight_in <= {$unsigned(2), $unsigned(-2), 32'd1, 32'd1}; //3-1

        #(`CLK_PRD);
        weight_in <= {32'd2, $unsigned(-3), 32'd0, $unsigned(-1)};

        #(`CLK_PRD);
        weight_in <= {32'd2, $unsigned(-4), 32'd1, 32'd2};

        #(`CLK_PRD);
        weight_in <= 32'd0;

    end

    initial begin
        window_valid <= 0;
        window_in <= 0;

        #(15*`CLK_PRD);
        window_valid <= 1;
        window_in <= {32'd1, 32'd1, 32'd1, 32'd1, 32'd1, 32'd1, 32'd1, 32'd1, 32'd1,
                    32'd1, 32'd1, 32'd1, 32'd1, 32'd1, 32'd1, 32'd1, 32'd1, 32'd1,
                    32'd1, 32'd1, 32'd1, 32'd1, 32'd1, 32'd1, 32'd1, 32'd1, 32'd1,
                    32'd1, 32'd1, 32'd1, 32'd1, 32'd1, 32'd1, 32'd1, 32'd1, 32'd1};

        #(`CLK_PRD);
        window_in <= {$unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1),
                    $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1),
                    $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1),
                    $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1), $unsigned(-1)};

        #(`CLK_PRD);
        window_in <= {32'd2, 32'd10, 32'd6, 32'd8, 32'd3, 32'd5, 32'd7, 32'd0, 32'd1,
                    32'd1, $unsigned(-1), 32'd1, $unsigned(-1), 32'd1, $unsigned(-1), 32'd1, $unsigned(-1), 32'd1,
                    32'd7, 32'd7, 32'd4, 32'd6, 32'd2, 32'd5, 32'd1, 32'd6, 32'd3,
                    32'd2, 32'd0, 32'd3, 32'd1, 32'd2, 32'd0, 32'd3, 32'd1, 32'd2};
        
        #(`CLK_PRD);
        window_in <= {32'd4, 32'd2, $unsigned(-3), 32'd1, $unsigned(-1), 32'd2, $unsigned(-2), 32'd3, 32'd1,
                    32'd4, 32'd2, $unsigned(-3), 32'd1, $unsigned(-1), 32'd2, $unsigned(-2), 32'd3, 32'd1,
                    32'd4, 32'd2, $unsigned(-3), 32'd1, $unsigned(-1), 32'd2, $unsigned(-2), 32'd3, 32'd1,
                    32'd4, 32'd2, $unsigned(-3), 32'd1, $unsigned(-1), 32'd2, $unsigned(-2), 32'd3, 32'd1};

        #(`CLK_PRD);
        window_in <= 0;


   end

    always begin
        Clk = 1;
        #(`CLK_HALF);
        Clk = 0;
        #(`CLK_HALF);
    end

    always begin
        #(1);
        if ($time >= 28*`CLK_PRD)
            $finish;
    end


endmodule