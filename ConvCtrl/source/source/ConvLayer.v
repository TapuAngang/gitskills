/*
   ConvLayer.v
   功能：单层卷积
   （1）只可自动完成一次卷积运算，若要进行下一次卷积，需先reset；
   （2）权重参数为串行输入，reset过后，在weight_valid上升沿后，同步进入读取参数状态，读完3*3个参数后进入运算状态；
   （3）窗口数据为并行输入，数据由上层模块负责整理，本模块直接对数据作运算

   注意：weight的次序与window数据的次序相反，即：若weight输入的先后顺序为(1,1)~(3,3)，则window从低位到高位为(1,1)~(3,3)
*/

module ConvLayer
#(
   parameter DataWidth = 32,
   parameter KernelSize = 9
)
(
   Clk,
   Rst,
   weight_in,        //权重串行输入
   weight_valid,     //标志权重输入有效
   window_in,        //窗口数据并行输入
   window_valid,     //窗口数据有效

   result_out,       //乘加结果输出
   result_ready      //结果输出有效
);

   parameter WeightCountWidth = $clog2(KernelSize);

   input                               Clk;
   input                               Rst;
   input [DataWidth-1: 0]              weight_in;
   input                               weight_valid;
   input [KernelSize*DataWidth-1: 0]   window_in;
   input                               window_valid;

   output [DataWidth-1: 0]             result_out;
   output                              result_ready;

   reg [WeightCountWidth-1: 0]         weight_count;     //权重输入计数器，计满9个开始计算
   reg [KernelSize*DataWidth-1: 0]     weight_reg;       //寄存全部权重
   wire                                weight_ready;     //标志权重读取结束

   wire                                mult_valid;       //标志允许开始进行计算
   wire [KernelSize-1: 0]              mult_ready;       //标志乘法运算完成。每一级流水线接收到valid信号后，才会在下一周期释放ready信号，保证时序的正确
   wire [KernelSize*DataWidth-1: 0]    mult_result;      //乘法结果

   wire                                add1_valid;       //add1表示树形累加的第一层
   wire [3:0]                          add1_ready;
   wire [4*DataWidth-1: 0]             add1_result;
   reg  [DataWidth-1: 0]               mult9_delay11;    //第9个乘积不参与累加，需打三拍。delay1表示第一次寄存的结果。
   reg  [DataWidth-1: 0]               mult9_delay12;
   reg  [DataWidth-1: 0]               mult9_delay13;
   reg  [DataWidth-1: 0]               mult9_delay14;

   wire                                add2_valid;       //add2表示树形累加的第二层
   wire [1:0]                          add2_ready;
   wire [2*DataWidth-1: 0]             add2_result;
   reg  [DataWidth-1: 0]               mult9_delay21;    //delay2表示第二次寄存的结果
   reg  [DataWidth-1: 0]               mult9_delay22;
   reg  [DataWidth-1: 0]               mult9_delay23;
   reg  [DataWidth-1: 0]               mult9_delay24;

   wire                                add3_valid;       //add3表示树形累加的第三层
   wire                                add3_ready;
   wire [DataWidth-1: 0]               add3_result;
   reg  [DataWidth-1: 0]               mult9_delay31;
   reg  [DataWidth-1: 0]               mult9_delay32;
   reg  [DataWidth-1: 0]               mult9_delay33;
   reg  [DataWidth-1: 0]               mult9_delay34;

   wire                                add4_valid;
   wire                                add4_ready;
   wire [DataWidth-1: 0]               add4_result;


   //参数读取
   assign weight_ready = (weight_count == KernelSize);
   always @(posedge Clk) begin
      if (Rst) begin
         weight_count   <= 0;
         weight_reg     <= 0;
      end

      else begin
         if (weight_ready | ~weight_valid)      //若权重未录完，且输入权重有效，即录入一个权重
            ;
         else begin
            weight_reg[weight_count * DataWidth +: DataWidth]  <= weight_in;
            weight_count                                       <= weight_count + 1;
         end
      end
   end

   //乘法计算
   assign mult_valid = weight_ready & window_valid;
   genvar i;
   generate
      for (i = 0; i < KernelSize; i = i+1) begin
         Fmult UFmult (
            .Clk        (Clk),
            .Rst        (Rst),
            .round_cfg  (1),
            .en         (mult_valid),
            .flout_a    (window_in     [i * DataWidth +: DataWidth]),
            .flout_b    (weight_reg    [i * DataWidth +: DataWidth]),
            .flout_c    (mult_result   [i * DataWidth +: DataWidth]),
            .ready      (mult_ready    [i]) 
         );
      end
   endgenerate

   //树状累加
   //第一层
   assign add1_valid = &mult_ready;   //此处等待所有乘法运算完毕，再统一推进流水线（实际上所有乘法在同一周期完成）
   genvar j;
   generate
      for (j = 0; j < 4; j = j + 1) begin
         Fadder UFadder (
            .Clk        (Clk),
            .Rst        (Rst),
            .Valid      (add1_valid),
            .Number1    (mult_result[2*j*DataWidth +: DataWidth]),
            .Number2    (mult_result[(2*j+1)*DataWidth +: DataWidth]),
            .Result     (add1_result[j * DataWidth +: DataWidth]),
            .Ready      (add1_ready[j]) 
         );
      end
   endgenerate
   //第9个乘积不作加法，保存1周期
   always @(posedge Clk) begin
      if (Rst) begin
         mult9_delay11 <= 0;
         mult9_delay12 <= 0;
         mult9_delay13 <= 0;
         mult9_delay14 <= 0;
      end
      else begin
         mult9_delay11 <= mult_result[8*DataWidth +: DataWidth];
         mult9_delay12 <= mult9_delay11;
         mult9_delay13 <= mult9_delay12;
         mult9_delay14 <= mult9_delay13;
      end
   end

   //第二层
   assign add2_valid = &add1_ready;
   genvar k;
   generate
      for (k = 0; k < 2; k = k + 1) begin
         Fadder UFadder (
            .Clk        (Clk),
            .Rst        (Rst),
            .Valid      (add2_valid),
            .Number1    (add1_result[2*k*DataWidth +: DataWidth]),
            .Number2    (add1_result[(2*k+1)*DataWidth +: DataWidth]),
            .Result     (add2_result[k * DataWidth +: DataWidth]),
            .Ready      (add2_ready[k]) 
         );
      end
   endgenerate
   //第9个乘积不作加法，再保存1周期
   always @(posedge Clk) begin
      if (Rst) begin
         mult9_delay21 <= 0;
         mult9_delay22 <= 0;
         mult9_delay23 <= 0;
         mult9_delay24 <= 0;
      end
      else if (add2_valid) begin
         mult9_delay21 <= mult9_delay14;
         mult9_delay22 <= mult9_delay21;
         mult9_delay23 <= mult9_delay22;
         mult9_delay24 <= mult9_delay23;
      end
   end

   //第三层
   assign add3_valid = &add2_ready;
   Fadder UFadder3 (
         .Clk        (Clk),
         .Rst        (Rst),
         .Valid      (add3_valid),
         .Number1    (add2_result[0 +: DataWidth]),
         .Number2    (add2_result[DataWidth +: DataWidth]),
         .Result     (add3_result),
         .Ready      (add3_ready) 
      );

   //第9个乘积不作加法，再再保存1周期
   always @(posedge Clk) begin
      if (Rst) begin
         mult9_delay31 <= 0;
         mult9_delay32 <= 0;
         mult9_delay33 <= 0;
         mult9_delay34 <= 0;
      end
      else begin
         mult9_delay31 <= mult9_delay24;
         mult9_delay32 <= mult9_delay31;
         mult9_delay33 <= mult9_delay32;
         mult9_delay34 <= mult9_delay33;
      end
   end

   //第四层
   assign add4_valid = add3_ready;
   Fadder UFadder4 (
        .Clk        (Clk),
        .Rst        (Rst),
        .Valid      (add4_valid),
        .Number1    (add3_result),
        .Number2    (mult9_delay34),
        .Result     (add4_result),
        .Ready      (add4_ready) 
      );

   assign result_ready  = add4_ready;
   assign result_out    = add4_result;

endmodule