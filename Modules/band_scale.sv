/*
 * band_scale.sv
 *
 * Author: Yucheng Zang
 *
 * Create: Feb 13, 23	(Ex07)
 *
 * This module implements the functionality of a audio equalizer
 *
 * INPUT
 * POT	:	Represents A2D reading from the slider potentiometer used to set the
 *  		gain for the frequency band of the equalizer. This should be 
 *			regarded as a 12-bit unsigned number
 * audio:	Represents the signed 16-bit audio signal coming from a FIR filter
 *			for the particular band. This number is scaled by the potentiometer
 *			reading squared to produce the scaled result. Audio signal feeds 
 *			into this equalizer
 * OUTPUT
 * scaled:	Signed 16-bit output that is the scaled result of the input audio by
 *		 	the slider potentiometer reading. Audio signal comes out of this
 *			equalizer
 */
module band_scale (clk, rst_n, POT, audio, scaled);
	input clk;
	input rst_n;
	// Inputs & output
	input [11:0] POT;
	input signed [15:0] audio;
	output signed [15:0] scaled;
	
	// Internal signals
	logic [23:0] POT_sqr_unsigned;		// Square the pot reading, which gives 
										// 4X gain when the pot is at full, 1X 
										// gain when centered,and 0 when it is 
										// all the way low
								
	logic signed [12:0] POT_sqr_signed;	// [23:12] of POT_sqr_unsigned, but 
										// signed-extended with 1'b0
										
	logic signed [28:0] result_full_signed; // 29-bit signed 'full' product of 
											// audio * POT_sqr_signed. The 
											// [25:10] part will then feed into 
											// the output signal 'scaled'
											
	logic pos_sat_flag, neg_sat_flag;	// Saturate flags for positive and 
										// negative number
	
	// change assign statement to always_ff flop
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			POT_sqr_unsigned <= '0;
		else
			POT_sqr_unsigned <= POT * POT;
	end

	// assign POT_sqr_unsigned = POT * POT;
	assign POT_sqr_signed = {1'b0, POT_sqr_unsigned[23:12]};
	//assign result_full_signed = POT_sqr_signed * audio;

	// change assign statment to always_ff flop
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			result_full_signed <= '0;
		else
			result_full_signed <= POT_sqr_signed * audio;
	end

	
	// If number is positive and any bits in [27:25] of 'result_full_signed' are
	// 1, then set the pos_sat_flag to HIGH, else it should be LOW
	assign pos_sat_flag = ~result_full_signed[28] ? 
								|result_full_signed[27:25] ? 1 : 0
							: 0;
						
	// If number is negative and any bits in [27:25] of 'result_full_signed' are
	// 0, then set the neg_sat_flag to HIGH, else it should be LOW
	assign neg_sat_flag = result_full_signed[28] ?
								~&result_full_signed[27:25] ? 1 : 0
							: 0;
							
	// Saturate to the most postive or negative 16-bit number if the respective
	// flags are set, otherwise, 
	assign scaled = pos_sat_flag ? 16'h7FFF : 
					neg_sat_flag ? 16'h8000 :
					result_full_signed[25:10];
					
	// assign scaled = pos_sat_flag ? 16'h7FFF : result_full_signed[25:10];
	// assign scaled = neg_sat_flag ? 16'h8000 : result_full_signed[25:10];

endmodule