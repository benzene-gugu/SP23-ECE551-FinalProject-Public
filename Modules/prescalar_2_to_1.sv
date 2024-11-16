/*
 * prescalar_2_to_1.sv
 *
 * Author: Yucheng Zang
 * Create: Apr 17, 23 (HW 5)
 *
 * An 2-to-1 prescalar
 *
 * The output 'prescaled_signal' will be asserted once when the input signal 
 * 'raw_signal' has been asserted once
 *
 * Required modules:
 *  - rise_edge_detector.sv             (Rising Edge Detector for wrt_smpl)
 */
module prescalar_2_to_1 (
    input clk,                      // Clock
    input rst_n,                    // Async active low reset
    input raw_signal,               // The raw signal to be prescaled
    output prescaled_signal         // The pre-scaled signal
);


    /* <-------------------- Internal Logics --------------------> */
    logic [1:0] prescalar_reg;      // A 2-bit one-hot counter. Will rotate left
                                    // every time raw_signal goes HIGH (a rising
                                    // edge of raw_signal has been detected)

    logic raw_signal_rise;          // Asserted by the rising edge detector
                                    // when a rising edge of the 'raw_signal'
                                    // has occoured



    /* <---------------- Instantiate rise_edge_detector ----------------> */
    rise_edge_detector iRise (
                                .clk(clk),
                                .rst_n(rst_n),
                                .signal(raw_signal),
                                .rise_edge(raw_signal_rise)
                            );



    /* <------------ Implying 'prescalar_reg' one-hot counter ------------> */
    // As reset, 'prescalar_reg' loads in the value 2'b01. 
    // Every time a rising edge of 'raw_signal' is detected (indicated by 
    // raw_signal_rise), 'prescalar_reg' will shift left by 1 bit.
    // The bit 1 of 'prescalar_reg' (prescalar_reg[1]) is tied to the output 
    // 'prescaled_signal'
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n)
            prescalar_reg <= 2'b01;
        
        else if (raw_signal_rise) begin
            // Perform the rotation
            prescalar_reg[1] <= prescalar_reg[0];
            prescalar_reg[0] <= prescalar_reg[1];
        end
    end        

    // Ties the output signal 'prescaled_signal' with prescalar_reg[1]
    assign prescaled_signal = prescalar_reg[1];

endmodule