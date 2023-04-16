/*
    ConvAccum.v
    在4通道卷积的基础上加入累加功能
    当卷积运算的第一个结果完成时，卷积有效信号拉高，将作为请求信号，向外部存储器索要累加数据。
    累加数据到来之前，卷积结果保存在FIFO中。
*/
module ConvAccum
#(
    parameter DataWidth = 32,
    parameter InputDim = 4,
    parameter KernelSize = 9,
    parameter MaxRowWidth = 9,
    parameter MaxColWidth = 9
)
(
    Clk,
    Rst,

    row_in,
    col_in,

    weight_in,
    weight_valid,

    data_in,
    data_valid,

    accum_request,
    accum_in,
    accum_valid,

    result_out,
    result_ready
);

    input                               Clk;
    input                               Rst;

    input [MaxRowWidth-1: 0]            row_in;
    input [MaxColWidth-1: 0]            col_in;

    input [InputDim*DataWidth-1: 0]     weight_in;
    input                               weight_valid;

    input [InputDim*DataWidth-1: 0]     data_in;
    input                               data_valid;

    output                              accum_request;  //标志着第一个卷积结果已经产生，向外界索要累加数据
    input [DataWidth-1: 0]              accum_in;       //累加数据输入通道
    input                               accum_valid;    //累加数据输入有效

    output [DataWidth-1: 0]             result_out;
    output                              result_ready;
    

    wire [DataWidth-1: 0]               conv_result;    //卷积结果数据
    wire                                conv_ready;
    wire [DataWidth-1: 0]               conv_fifoed;    //经过fifo缓冲的卷积数据

    wire                                add_valid;
    wire                                add_ready;
    wire [DataWidth-1: 0]               add_result;

    //卷积运算模块
    ConvChannel #(
        .DataWidth      (DataWidth),
        .InputDim       (InputDim),
        .KernelSize     (KernelSize),
        .MaxRowWidth    (MaxRowWidth),
        .MaxColWidth    (MaxColWidth))
    UConvLayer(
        .Clk            (Clk),
        .Rst            (Rst),

        .row_in         (row_in),
        .col_in         (col_in),

        .weight_in      (weight_in),
        .weight_valid   (weight_valid),

        .data_in        (data_in),
        .data_valid     (data_valid),

        .result_out     (conv_result),
        .result_ready   (conv_ready)
    );

    assign accum_request = conv_ready;

    //运算结果缓冲
    Fifo16 UFifo16 (
        .clk        (Clk),
        .rst        (Rst),
        .wr_data    (conv_result),
        .wr_en      (conv_ready),
        .rd_en      (accum_valid),
        .rd_data    (conv_fifoed)
    );

    //累加运算
    assign add_valid = accum_valid & ~Rst; //原始累加数据有效，且未复位
    Adder #(.DataWidth (DataWidth))
    Uadder (
        .aclk                   (Clk),
        .s_axis_a_tvalid        (add_valid),
        .s_axis_a_tdata         (accum_in),
        .s_axis_b_tvalid        (add_valid),
        .s_axis_b_tdata         (conv_fifoed),
        .m_axis_result_tvalid   (add_ready),
        .m_axis_result_tdata    (add_result)
    );

    assign result_ready = add_ready;
    assign result_out = add_result;

endmodule