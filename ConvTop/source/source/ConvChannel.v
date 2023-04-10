/*
   ConvChannel模块：实现4个输入通道的卷积与累加
   1、录入权重，要求一个周期并行输入4个权重数据（暂定，不过也挺合理，因为数据的输入也是4个并行的）
   2、权重和数据，统一要求序号小的通道在低位，序号大的通道在高位（weight_in[i*DataWidth +: DataWidth]）
*/
module ConvChannel
#(
   parameter DataWidth = 32,
   parameter InputDim = 4,
   parameter KernelSize = 9
)
(
   Clk,
   Rst,

   weight_in,
   weight_valid,

   window_in,
   window_valid,

   result_out,
   result_ready
);

   input                                        Clk;
   input                                        Rst;

   input [InputDim*DataWidth-1: 0]              weight_in;     //4个权重并行输入
   input                                        weight_valid;

   input [InputDim*KernelSize*DataWidth-1: 0]   window_in;     //4个数据窗口并行输入，数据来自4个行缓存器
   input                                        window_valid;

   output [DataWidth-1: 0]                      result_out;
   output                                       result_ready;

   wire [InputDim*DataWidth-1: 0]               conv_result;
   wire [InputDim-1: 0]                         conv_ready;

   wire                                         add1_valid;
   wire [2*DataWidth-1: 0]                      add1_result;
   wire [1:0]                                   add1_ready;

   wire                                         add2_valid;
   wire [DataWidth-1: 0]                        add2_result;
   wire                                         add2_ready;

   genvar i;
   generate 
      for (i = 0; i < InputDim; i = i + 1) begin
         ConvLayer #(.DataWidth (DataWidth), .KernelSize (KernelSize))
         UConvLayer (
            .Clk           (Clk),
            .Rst           (Rst),
            .weight_in     (weight_in[i*DataWidth +: DataWidth]),
            .weight_valid  (weight_valid),
            .window_in     (window_in[i*KernelSize*DataWidth +: KernelSize*DataWidth]),
            .window_valid  (window_valid),

            .result_out    (conv_result[i*DataWidth +: DataWidth]),
            .result_ready  (conv_ready[i])
         );
      end
   endgenerate

   //将4个卷积结果进行树状累加
   //第一层
   assign add1_valid = &conv_ready & ~Rst;      //valid信号需引入复位信号
   //1、2相加
   Adder #(.DataWidth (DataWidth))
   Uadder1 (
      .aclk                   (Clk),
      .s_axis_a_tvalid        (add1_valid),
      .s_axis_a_tdata         (conv_result[0 +: DataWidth]),
      .s_axis_b_tvalid        (add1_valid),
      .s_axis_b_tdata         (conv_result[DataWidth +: DataWidth]),
      .m_axis_result_tvalid   (add1_ready[0]),
      .m_axis_result_tdata    (add1_result[0 +: DataWidth])
   );

   //3、4相加
   Adder #(.DataWidth (DataWidth))
   Uadder2 (
      .aclk                   (Clk),
      .s_axis_a_tvalid        (add1_valid),
      .s_axis_a_tdata         (conv_result[2*DataWidth +: DataWidth]),
      .s_axis_b_tvalid        (add1_valid),
      .s_axis_b_tdata         (conv_result[3*DataWidth +: DataWidth]),
      .m_axis_result_tvalid   (add1_ready[1]),
      .m_axis_result_tdata    (add1_result[DataWidth +: DataWidth])
   );

   //第二层，两个加法的结果相加
   assign add2_valid = &add1_ready & ~Rst;
   Adder #(.DataWidth (DataWidth))
   Uadder3 (
      .aclk                   (Clk),
      .s_axis_a_tvalid        (add2_valid),
      .s_axis_a_tdata         (add1_result[0 +: DataWidth]),
      .s_axis_b_tvalid        (add2_valid),
      .s_axis_b_tdata         (add1_result[DataWidth +: DataWidth]),
      .m_axis_result_tvalid   (add2_ready),
      .m_axis_result_tdata    (add2_result)
   );

   assign result_out = add2_result;
   assign result_ready = add2_ready;

endmodule