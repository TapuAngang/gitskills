/*
    ConvTop.v：卷积运算顶层模块
    支持4个输入通道，1个输出通道的卷积，图像尺寸最大为416*416
    要求：
        1、复位：同步复位。一次运算完成后，必须先复位才能进行下一次运算。
        2、权重：串行输入，但同一周期内4通道的数据并行输入。通道数据并列存放的要求是——标号低的数据在低位。
                valid信号不要求连续，信号有效期间每个时钟上升沿算作1个权重输入。
        3、数据：串行输入，但同一周期内4通道的数据并行输入。
                valid信号实际上没有严格要求，只要求第一个有效数据输入时valid拉高。本模块只判断data_valid信号上升沿，并在处理整个运算后自动结束进程。
        4、时序：权重输入全部完成后，才允许输入数据。
                第一个数据输入后，经过
*/

module ConvTop 
#(
    parameter DataWidth = 64,
    parameter KernelSize = 9,
    parameter InputDim = 4,
    parameter MaxRowWidth = 9,  //图像最大为416*416，需9位数据
    parameter MaxColWidth = 9
)
(
    Clk,
    Rst,
    col_in,
    row_in,

    weight_in,
    weight_valid,

    data_in,
    data_valid,

    result_out,
    result_ready
);

    input                                       Clk;            //时钟
    input                                       Rst;            //同步复位信号
    input [MaxRowWidth-1: 0]                    row_in;         //图像行尺寸
    input [MaxColWidth-1: 0]                    col_in;         //图像列尺寸

    input [InputDim*DataWidth-1: 0]             weight_in;      //权重串行输入
    input                                       weight_valid;   //权重哦有效信号

    input [InputDim*DataWidth-1: 0]             data_in;        //数据串行输入
    input                                       data_valid;     //数据有效信号

    output [DataWidth-1: 0]                     result_out;     //卷积结果串行输出
    output                                      result_ready;   //结果有效信号

    wire [InputDim*KernelSize*DataWidth-1: 0]   window_trans;   //中转数据窗口
    wire [InputDim-1: 0]                        window_ready;   //LineBuffer数据装载完成
    wire                                        window_ready_all;

    //LineBuffer连接
    genvar i;
    generate
        for (i = 0; i < InputDim; i = i + 1) begin
            LineBuffer #(
                .DataWidth      (DataWidth),
                .KernelSize     (KernelSize),
                .MaxRowWidth    (MaxRowWidth),
                .MaxColWidth    (MaxColWidth)) 
            ULineBuffer (
                .Clk            (Clk),
                .Rst            (Rst),
                .row_in         (row_in),
                .col_in         (col_in),
                .data_in        (data_in[i*DataWidth +: DataWidth]),
                .data_valid     (data_valid),
                .window_out     (window_trans[i*KernelSize*DataWidth +: KernelSize*DataWidth]),
                .window_valid   (window_ready[i])
            );
        end
    endgenerate

    //ConvChannel连接
    assign window_ready_all = & window_ready;
    ConvChannel #(
        .DataWidth      (DataWidth),
        .InputDim       (InputDim),
        .KernelSize     (KernelSize))
    UConvChannel (
        .Clk            (Clk),
        .Rst            (Rst),
        .weight_in      (weight_in),
        .weight_valid   (weight_valid),
        .window_in      (window_trans),
        .window_valid   (window_ready_all),
        .result_out     (result_out),
        .result_ready   (result_ready)
    );

endmodule