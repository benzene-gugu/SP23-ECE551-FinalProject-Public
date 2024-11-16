module BT_intf_tb ();
	logic clk, rst_n;
	logic next_n, prev_n;
	logic cmd_n;
	logic TX;
	logic RX;
	logic vld;
	
	logic I2S_sclk, I2S_ws, I2S_data;
	logic [23:0] lft_chnnl, rght_chnnl, lft_smpld, rght_smpld;

	I2S_Serf iI2S (.clk(clk), .rst_n(rst_n), .I2S_sclk(I2S_sclk), .I2S_ws(I2S_ws), .I2S_data(I2S_data), .lft_chnnl(lft_chnnl), .rght_chnnl(rght_chnnl), .vld(vld));
	BT_intf iDUT (.clk(clk), .rst_n(rst_n), .next_n(next_n), .prev_n(prev_n), .RX(RX), .TX(TX), .cmd_n(cmd_n));
	RN52 iRN (.clk(clk), .RST_n(rst_n), .cmd_n(cmd_n), .RX(TX), .TX(RX), .I2S_sclk(I2S_sclk), .I2S_data(I2S_data), .I2S_ws(I2S_ws));

	always_ff @(posedge clk)
		if (vld) begin
			lft_smpld <= lft_chnnl;
			rght_smpld <= rght_chnnl;
		end

	initial begin
		clk = 0;
		rst_n = 0;
		next_n = 1;
		prev_n = 1;

		// song 0
		@(posedge clk);
		@(negedge clk) rst_n = 1;
		repeat (600000) @(posedge clk);

		// use next_n to go to song 1
		@(posedge clk);
		next_n = 0;
		repeat (5000) @(posedge clk);
		next_n = 1;
		repeat (600000) @(posedge clk);

		// use next_n to go to song 2
		@(posedge clk);
		next_n = 0;
		repeat (5000) @(posedge clk);
		next_n = 1;
		repeat (600000) @(posedge clk);

		// use next_n to go to song 3
		@(posedge clk);
		next_n = 0;
		repeat (5000) @(posedge clk);
		next_n = 1;
		repeat (600000) @(posedge clk);

		// use prev_n to go back to song 2
		@(posedge clk);
		prev_n = 0;
		repeat (5000) @(posedge clk);
		prev_n = 1;
		repeat (600000) @(posedge clk);

		// use prev_n to go back to song 1
		@(posedge clk);
		prev_n = 0;
		repeat (5000) @(posedge clk);
		prev_n = 1;
		repeat (600000) @(posedge clk);

		// use prev_n to go back to song 0
		@(posedge clk);
		prev_n = 0;
		repeat (5000) @(posedge clk);
		prev_n = 1;
		repeat (600000) @(posedge clk);
		$stop();
	end

	always
		#5 clk = ~clk;
endmodule
