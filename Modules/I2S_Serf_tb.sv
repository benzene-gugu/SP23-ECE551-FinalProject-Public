module I2S_Serf_tb ();
	logic clk, rst_n;
	logic I2S_sclk, I2S_ws, I2S_data;
	logic [23:0] lft_chnnl, rght_chnnl;
	logic vld;

	// I2S_Monarch
	I2S_Monarch monarch (.clk(clk), .rst_n(rst_n), .I2S_sclk(I2S_sclk), .I2S_ws(I2S_ws), .I2S_data(I2S_data));
	// iDUT: I2S_Serf
	I2S_Serf iDUT (.clk(clk), .rst_n(rst_n), .I2S_sclk(I2S_sclk), .I2S_ws(I2S_ws), .I2S_data(I2S_data), 
			.lft_chnnl(lft_chnnl), .rght_chnnl(rght_chnnl), .vld(vld));

	// flip-flops to generate left sampled and right sampled
	logic [23:0] lft_smpld, rght_smpld;
	always_ff @(posedge clk)
		if (vld) begin
			lft_smpld <= lft_chnnl;
			rght_smpld <= rght_chnnl;
		end
	
	//run for 700000 clocks
	initial begin
		clk = 0;
		rst_n = 0;

		@(posedge clk);
		@(negedge clk) rst_n = 1;

		repeat (1400000)@(posedge clk);
		$stop(); 
	end

	always
		#5 clk = ~clk;
endmodule
