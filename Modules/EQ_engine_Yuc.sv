/*
 * EQ_engine_Yuc.sv
 *
 * Author: Yucheng Zang
 * Create: Apr 24, 23 (Final Project)
 *
 * A equalizer engine which takes two audio input signals (aud_in_lft and 
 * aud_in_rght), applys equalizer filters according to user's setting (positions 
 * of the sliders POT_LP, POT_B1, POT_B2, POT_B3 and POT_HP), and outputs two 
 * streams of filter audio signals (aud_out_lft and aud_out_rght)
 *
 * Required modules:
 *  - low_freq_queue.sv             (Circular queue for low frequency signals)
 *      - rise_edge_detector.sv     (Rising Edge Detector for wrt_smpl)
 *      - prescalar_2_to_1.sv       (2-to-1 Prescaler used for wrt_smpl)
 *      - dualPort1024x16.v         (1024 * 16 dual port memory)
 *  - high_freq_queue.sv            (Circular queue for high frequency signals)
 *      - rise_edge_detector.sv     (same module as required by 'low_freq_queue')
 *      - dualPort1536x16.v         (1536 * 16 dual port memory)
 *  - FIR_x.sv                      (Frequency impuse filter used to filter each 
 *                                   frequency bands out, note that caller needs
 *                                   to pass frequency intended to filter as 
 *                                   parameter)
 *  - band_scale.sv                 (Scale the incoming audio signal according 
 *                                   to user's input)
 */
module EQ_engine_Yuc (
    input clk,                      // Global clock signal
    input rst_n,                    // Async active low reset signal
    input signed [15:0] aud_in_lft,        // Audio input for the left channel
    input signed [15:0] aud_in_rght,       // Audio input for the right channel
    input vld,                      // Assert to read next pair of data
    input [11:0] POT_LP,            // Position of LP (low pass) slider
    input [11:0] POT_B1,            // Position of B1 (band 1) slider
    input [11:0] POT_B2,            // Position of B2 (band 2) slider
    input [11:0] POT_B3,            // Position of B3 (band 3) slider
    input [11:0] POT_HP,            // Position of HP (high pass) slider
    input [11:0] POT_VOL,           // Position of VOL (volume) slider
    output signed [15:0] aud_out_lft,      // Audio ouptut for the left channel
    output signed [15:0] aud_out_rght ,     // Audio output for the right channel
    output logic seq_low           // to indicate if the low qeue is full or not
);



    /* <-------------------- Internal Logics --------------------> */
    // Signals connecting the circular queues and the FIR filters
    logic signed [15:0] low_freq_left_out;     // Output signal 'lft_out' of module 
                                        // 'low_freq_queue'
    logic signed [15:0] low_freq_right_out;    // Output signal 'rght_out' of module 
                                        // 'low_freq_queue'
    logic signed [15:0] high_freq_left_out;    // Output signal 'lft_out' of module 
                                        // 'high_freq_queue'
    logic signed [15:0] high_freq_right_out;   // Output signal 'rght_out' of module 
                                        // 'high_freq_queue'

    logic low_freq_sequencing;          // Output signal 'sequencing' of module 
                                        // 'low_freq_queue'
    logic high_freq_sequencing;         // Output signal 'sequencing' of module 
                                        // 'high_freq_queue'


    // Signals connecting the FIR filters and the band scaler modules
    logic signed [15:0] FIR_LP_left_out;       // Output signal 'lft_out' of module 
                                        // 'iFIR_LP'
    logic signed [15:0] FIR_LP_right_out;      // Output signal 'rght_out' of module 
                                        // 'iFIR_LP'

    logic signed [15:0] FIR_B1_left_out;       // Output signal 'lft_out' of module 
                                        // 'iFIR_B1'
    logic signed [15:0] FIR_B1_right_out;      // Output signal 'rght_out' of module 
                                        // 'iFIR_B1'

    logic signed [15:0] FIR_B2_left_out;       // Output signal 'lft_out' of module 
                                        // 'iFIR_B2'
    logic signed [15:0] FIR_B2_right_out;      // Output signal 'rght_out' of module 
                                        // 'iFIR_B2'
                                        
    logic signed [15:0] FIR_B3_left_out;       // Output signal 'lft_out' of module 
                                        // 'iFIR_B3'
    logic signed [15:0] FIR_B3_right_out;      // Output signal 'rght_out' of module 
                                        // 'iFIR_B3'

    logic signed [15:0] FIR_HP_left_out;       // Output signal 'lft_out' of module 
                                        // 'iFIR_HP'
    logic signed [15:0] FIR_HP_right_out;      // Output signal 'rght_out' of module 
                                        // 'iFIR_HP'    
    

    // Signals connecting the band scalers with the signal summer
    logic signed [15:0] scaled_LP_left; // Output signal 'scaled' of module 
                                        // 'iBand_scale_LP_left'
    logic signed [15:0] scaled_LP_right;// Output signal 'scaled' of module 
                                        // 'iBand_scale_LP_right'

    logic signed [15:0] scaled_B1_left; // Output signal 'scaled' of module 
                                        // 'iBand_scale_B1_left'
    logic signed [15:0] scaled_B1_right;// Output signal 'scaled' of module 
                                        // 'iBand_scale_B1_right'

    logic signed [15:0] scaled_B2_left; // Output signal 'scaled' of module 
                                        // 'iBand_scale_B2_left'
    logic signed [15:0] scaled_B2_right;// Output signal 'scaled' of module 
                                        // 'iBand_scale_B2_right'

    logic signed [15:0] scaled_B3_left; // Output signal 'scaled' of module 
                                        // 'iBand_scale_B3_left'
    logic signed [15:0] scaled_B3_right;// Output signal 'scaled' of module 
                                        // 'iBand_scale_B3_right'

    logic signed [15:0] scaled_HP_left; // Output signal 'scaled' of module 
                                        // 'iBand_scale_HP_left'
    logic signed [15:0] scaled_HP_right;// Output signal 'scaled' of module 
                                        // 'iBand_scale_HP_right'

    // Flop to resolve timing issue
    logic signed [15:0] scaled_LP_left_flop; 
    logic signed [15:0] scaled_LP_right_flop;

    logic signed [15:0] scaled_B1_left_flop; 
    logic signed [15:0] scaled_B1_right_flop;

    logic signed [15:0] scaled_B2_left_flop; 
    logic signed [15:0] scaled_B2_right_flop; 

    logic signed [15:0] scaled_B3_left_flop; 
    logic signed [15:0] scaled_B3_right_flop;

    logic signed [15:0] scaled_HP_left_flop; 
    logic signed [15:0] scaled_HP_right_flop;

    // Signals connecting the adder and mutiplier
    logic signed [15:0] sum_audio_left; // Output of the left audio adder
    logic signed [15:0] sum_audio_right;// Output of the right audio adder 
    

                                    
    /* <--------------- Instantiate the Circular Queues ---------------> */
    // These circular queues are used to store audio signal temporarily and feed 
    // data into the frequency impulse filter (FIR). 
    // Due to the nature of the frequency impulse filter, it needs the current
    // data and a lot of previous data at once, so this circular queue is going
    // to provide a large stream of data at once.
    // Low frequency queue's (iLow_Queue) output will feed into the low pass 
    // filter (iFIR_LP) and band 1 (iFIR_B1), where the high frequency queue's 
    // (iHigh_Queue) output will feed into the band 2 (iFIR_B2), band 3 (iFIR_B3)
    // , and high pass filter (iFIR_HP)

    // The low frequency queue
    low_freq_queue iLow_Queue (
                                .clk(clk),
                                .rst_n(rst_n),
                                .lft_smpl(aud_in_lft),
                                .rght_smpl(aud_in_rght),
                                .wrt_smpl(vld),
                                .lft_out(low_freq_left_out),
                                .rght_out(low_freq_right_out),
                                .sequencing(low_freq_sequencing),
                                .queue_full(seq_low)
                            );

    // The low frequency queue
    high_freq_queue iHigh_Queue (
                                .clk(clk),
                                .rst_n(rst_n),
                                .lft_smpl(aud_in_lft),
                                .rght_smpl(aud_in_rght),
                                .wrt_smpl(vld),
                                .lft_out(high_freq_left_out),
                                .rght_out(high_freq_right_out),
                                .sequencing(high_freq_sequencing)
                            );

    

    /* <------------ Instantiate the Frequency Impulse Filters ------------> */
    // There are totally 5 different frequency inpulse filters (FIRs), and each
    // is used to filter different frequencies of the audio.
    //
    // Low frequency queue's output will feed into the low pass filter (iFIR_LP)
    // and band 1 (iFIR_B1), where the high frequency queue's output will feed 
    // into the band 2 (iFIR_B2), band 3 (iFIR_B3) , and high pass filter 
    // (iFIR_HP)

    FIR_x #(.BAND(0)) iFIR_LP (
                                .clk(clk),
                                .rst_n(rst_n),
                                .lft_in(low_freq_left_out),
                                .rght_in(low_freq_right_out),
                                .sequencing(low_freq_sequencing),
                                .lft_out(FIR_LP_left_out),
                                .rght_out(FIR_LP_right_out)
                                );

    FIR_x #(.BAND(1)) iFIR_B1 (
                                .clk(clk),
                                .rst_n(rst_n),
                                .lft_in(low_freq_left_out),
                                .rght_in(low_freq_right_out),
                                .sequencing(low_freq_sequencing),
                                .lft_out(FIR_B1_left_out),
                                .rght_out(FIR_B1_right_out)
                                );
    
    FIR_x #(.BAND(2)) iFIR_B2 (
                                .clk(clk),
                                .rst_n(rst_n),
                                .lft_in(high_freq_left_out),
                                .rght_in(high_freq_right_out),
                                .sequencing(high_freq_sequencing),
                                .lft_out(FIR_B2_left_out),
                                .rght_out(FIR_B2_right_out)
                                );

    FIR_x #(.BAND(3)) iFIR_B3 (
                                .clk(clk),
                                .rst_n(rst_n),
                                .lft_in(high_freq_left_out),
                                .rght_in(high_freq_right_out),
                                .sequencing(high_freq_sequencing),
                                .lft_out(FIR_B3_left_out),
                                .rght_out(FIR_B3_right_out)
                                );

    FIR_x #(.BAND(4)) iFIR_HP (
                                .clk(clk),
                                .rst_n(rst_n),
                                .lft_in(high_freq_left_out),
                                .rght_in(high_freq_right_out),
                                .sequencing(high_freq_sequencing),
                                .lft_out(FIR_HP_left_out),
                                .rght_out(FIR_HP_right_out)
                                );



    /* <------------ Instantiate the Band Scale Filters ------------> */
    // The band scale filters will scale the audio signal of each band (coming 
    // from each band's FIR filters) according to user's input on the sliders
    band_scale iBand_scale_LP_left (.clk(clk),
                                    .rst_n(rst_n),
                                    .POT(POT_LP),
                                    .audio(FIR_LP_left_out),
                                    .scaled(scaled_LP_left)
                                    );

    band_scale iBand_scale_LP_right (.clk(clk),
                                    .rst_n(rst_n),
                                    .POT(POT_LP),
                                    .audio(FIR_LP_right_out),
                                    .scaled(scaled_LP_right)
                                    );
                                    
    band_scale iBand_scale_B1_left (.clk(clk),
                                    .rst_n(rst_n),
                                    .POT(POT_B1),
                                    .audio(FIR_B1_left_out),
                                    .scaled(scaled_B1_left)
                                    );

    band_scale iBand_scale_B1_right (.clk(clk),
                                    .rst_n(rst_n),
                                    .POT(POT_B1),
                                    .audio(FIR_B1_right_out),
                                    .scaled(scaled_B1_right)
                                    );

    band_scale iBand_scale_B2_left (.clk(clk),
                                    .rst_n(rst_n),
                                    .POT(POT_B2),
                                    .audio(FIR_B2_left_out),
                                    .scaled(scaled_B2_left)
                                    );

    band_scale iBand_scale_B2_right (.clk(clk),
                                    .rst_n(rst_n),
                                    .POT(POT_B2),
                                    .audio(FIR_B2_right_out),
                                    .scaled(scaled_B2_right)
                                    );

    band_scale iBand_scale_B3_left (.clk(clk),
                                    .rst_n(rst_n),
                                    .POT(POT_B3),
                                    .audio(FIR_B3_left_out),
                                    .scaled(scaled_B3_left)
                                    );

    band_scale iBand_scale_B3_right (.clk(clk),
                                    .rst_n(rst_n),
                                    .POT(POT_B3),
                                    .audio(FIR_B3_right_out),
                                    .scaled(scaled_B3_right)
                                    );

    band_scale iBand_scale_HP_left (.clk(clk),
                                    .rst_n(rst_n),
                                    .POT(POT_HP),
                                    .audio(FIR_HP_left_out),
                                    .scaled(scaled_HP_left)
                                    );

    band_scale iBand_scale_HP_right (.clk(clk),
                                    .rst_n(rst_n),
                                    .POT(POT_HP),
                                    .audio(FIR_HP_right_out),
                                    .scaled(scaled_HP_right)
                                    );

    // Flop the signal comming out of the band scaler to resolve timing issue
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            scaled_LP_left_flop <= 16'h0000;
            scaled_LP_right_flop <= 16'h0000;
            scaled_B1_left_flop <= 16'h0000;
            scaled_B1_right_flop <= 16'h0000;
            scaled_B2_left_flop <= 16'h0000;
            scaled_B2_right_flop <= 16'h0000;
            scaled_B3_left_flop <= 16'h0000;
            scaled_B3_right_flop <= 16'h0000;
            scaled_HP_left_flop <= 16'h0000;
            scaled_HP_right_flop <= 16'h0000;
        end else begin
            scaled_LP_left_flop <= scaled_LP_left;
            scaled_LP_right_flop <= scaled_LP_right;
            scaled_B1_left_flop <= scaled_B1_left;
            scaled_B1_right_flop <= scaled_B1_right;
            scaled_B2_left_flop <= scaled_B2_left;
            scaled_B2_right_flop <= scaled_B2_right;
            scaled_B3_left_flop <= scaled_B3_left;
            scaled_B3_right_flop <= scaled_B3_right;
            scaled_HP_left_flop <= scaled_HP_left;
            scaled_HP_right_flop <= scaled_HP_right;
        end
    end



    /* <-------------------- Add Up The Scaled Signals --------------------> */
    // Use a flop to resolve timing issue
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n)
            sum_audio_left <= 16'h0000;
        else 
            sum_audio_left <= scaled_LP_left_flop + scaled_B1_left_flop + scaled_B2_left_flop 
                            + scaled_B3_left_flop + scaled_HP_left_flop;
    end

    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n)
            sum_audio_right <= 16'h0000;
        else 
            sum_audio_right <= scaled_LP_right_flop + scaled_B1_right_flop + scaled_B2_right_flop 
                            + scaled_B3_right_flop + scaled_HP_right_flop;
    end


    // MOD.
    // assign sum_audio_left = scaled_LP_left + scaled_B1_left + scaled_B2_left 
    //                         + scaled_B3_left + scaled_HP_left;
    // assign sum_audio_right = scaled_LP_right + scaled_B1_right + scaled_B2_right 
    //                         + scaled_B3_right + scaled_HP_right;



    /* <------ Multiply Scaled Signals with Volume Slider's Position ------> */	
	logic signed [12:0] lft_1, rght_1;
	logic signed [28:0] temp_lft, temp_rght;
	
    assign lft_1 = {1'b0, POT_VOL};
    assign rght_1 = {1'b0, POT_VOL};
	
	// assign aud_out_lft = sum_audio_left * lft_1;
	// assign aud_out_rght = sum_audio_right * rght_1;
	
	assign temp_lft = sum_audio_left * lft_1;
	assign temp_rght = sum_audio_right * rght_1;
    assign aud_out_lft = temp_lft[27:12];
    assign aud_out_rght = temp_rght[27:12];


endmodule
