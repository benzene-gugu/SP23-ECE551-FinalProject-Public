/*
 * rise_edge_detector.sv
 *
 * Author: Yucheng Zang
 * Create: Apr 17, 23 (HW 5)
 *
 * A rising edge dector
 *
 * The output signal 'rise_edge' will be asserted when a rising edge has 
 * occoured to the input signal 'signal'
 */
module rise_edge_detector (
    input clk,              // Clock
    input rst_n,            // Async active low reset
    input signal,           // The signal intend to monitor rising edge
    output rise_edge        // Will be asserted by this module when a rising 
                            // edge has occoured to 'signal'
);



    /* <-------------------- Internal Logics --------------------> */
    // The incomming signal is double floped to avoid metastabillity
	reg rise_FF1_out, rise_FF2_out, rise_FF3_out;



    /* <----------------- Implying The Three Flops -----------------> */
	// Note that the first flop is connected to the asynch 'signal', and the 
	// reset signal (rst_n) is used to preset the flops
    // ! Might be able to remove the first flop
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			rise_FF1_out <= 1'b1;
			rise_FF2_out <= 1'b1;
			rise_FF3_out <= 1'b1;
		end else begin
			rise_FF1_out <= signal;
			rise_FF2_out <= rise_FF1_out;
			rise_FF3_out <= rise_FF2_out;
		end
	end

    // The combination logic that detects the rising edge. 
	// If FF2_out reads HIGH and FF3_out reads LOW, then it indicates a rising 
	// edge
	assign rise_edge = rise_FF2_out & ~rise_FF3_out;

endmodule