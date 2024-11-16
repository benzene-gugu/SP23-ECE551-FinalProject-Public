module  rst_synch (
	input  logic RST_n, // raw input from the push button
	input  logic clk,   // system clock input
	output logic rst_n // synchronized output used for the reset signal
);

	// Declare internal signals being used
	logic intermediate; // intermediate signal being used to avoid metastability
	
	// Instantiate seires of flops to resolve metastability
	always_ff @(negedge clk, negedge RST_n) begin
		if(!RST_n) begin
			intermediate <= 1'b0;
			rst_n <= 1'b0;
		end
		else begin
			intermediate <= 1'b1;
			rst_n <= intermediate;
		end
	end

endmodule