// @author: Tianqi Shen

/*
 Use synchronized rst_n from rst_synch.sv to detect the release of push button
*/
module PB_release
(
	input		PB,			// push button signal
	input		clk,			// clock
	input		rst_n,			// synchronized rst_n
	output 		released		// PB released signal
);



// Declare internal signals  
logic PB1, PB2, PB3;

// Sequential logic of 3 FFs to pipeline PB
always_ff @(posedge clk, negedge rst_n) begin
   if (!rst_n) begin
      {PB1, PB2, PB3} <= 3'b111;
   end
   else begin
      PB1 <= PB;
      PB2 <= PB1;
      PB3 <= PB2;
   end
end


//  detect posedge PB  
and and0(released, PB2, ~PB3);


endmodule
