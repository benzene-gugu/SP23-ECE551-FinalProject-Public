`default_nettype none
module FIR_x_tb();

    // Declare global control signals
    logic clk;   // Clock signal
    logic rst_n; // Asynchronous active low reset signal

    // Instantiate the clock signal
    always begin
        #5 clk = ~clk;
    end

    // Declare UART output signals
    logic TX; // UART transmit signal

    // Declare I2S communication signals
    logic I2S_sclk; // I2S serial clock signal
    logic I2S_data; // I2S data signal
    logic I2S_ws;   // I2S word select signal

    // Declare the unfiltered signals
    logic [23:0] left_sampled;     // sampled left channel data
    logic [23:0] right_sampled;    // sampled right channel data
    logic [15:0] left_unfiltered;  // unfiltered left channel data
    logic [15:0] right_unfiltered; // unfiltered right channel data
    logic        valid;            // valid signal for the channel data

    // Declare the outputs for the queue
    logic [15:0] left_out;   // left channel data from the queue
    logic [15:0] right_out;  // right channel data from the queue
    logic        sequencing; // sequencing signal for the queue

    // Declare the outputs for the FIR filter
    logic [15:0] left_filtered;  // filtered left channel data
    logic [15:0] right_filtered; // filtered right channel data
    logic [15:0] left_channel;   // left channel data after filter
    logic [15:0] right_channel;  // right channel data after filter

    // Instantiate the DUTs
    RN52 iRN (
        .clk,
        .RST_n(rst_n),
        .cmd_n(1'b1),
        .RX(1'b1),
        .TX,
        .I2S_sclk,
        .I2S_data,
        .I2S_ws
    );

    I2S_Serf iSub (
        .clk,
        .rst_n,
        .I2S_sclk,
        .I2S_data,
        .I2S_ws,
        .lft_chnnl(left_sampled),
        .rght_chnnl(right_sampled),
        .vld(valid)
    );

    always_ff @(posedge clk,negedge rst_n) begin
        if(!rst_n) begin
            left_unfiltered <= '0;
            right_unfiltered <= '0;
        end
        else begin
            if(valid) begin
                left_unfiltered <= left_sampled[23:8];
                right_unfiltered <= right_sampled[23:8];
            end
        end
    end

    high_freq_queue iQueue (
        .clk,
        .rst_n,
        .lft_smpl(left_sampled[23:8]),
        .rght_smpl(right_sampled[23:8]),
        .wrt_smpl(valid),
        .lft_out(left_out),
        .rght_out(right_out),
        .sequencing
    );

    FIR_x #(.BAND(2)) iFIR (
        .clk,
        .rst_n,
        .lft_in(left_out),
        .rght_in(right_out),
        .sequencing,
        .lft_out(left_filtered),
        .rght_out(right_filtered)
    );

    always_ff @(posedge clk,negedge rst_n) begin
        if(!rst_n) begin
            left_channel <= '0;
            right_channel <= '0;
        end
        else begin
            if(valid) begin
                left_channel <= left_filtered;
                right_channel <= right_filtered;
            end
        end
    end

    // Start the testbench simulation
    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        @(posedge clk);
        rst_n = 1'b1;
        repeat(2100000) @(posedge clk);
        $stop();
    end

endmodule
`default_nettype wire