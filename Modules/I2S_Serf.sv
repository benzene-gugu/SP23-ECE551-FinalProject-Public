`default_nettype none
module I2S_Serf (clk, rst_n, I2S_sclk, I2S_ws, I2S_data, lft_chnnl, rght_chnnl, vld);
	input logic clk, rst_n;
	input logic I2S_sclk, I2S_ws, I2S_data;
	output logic [23:0] lft_chnnl, rght_chnnl;
	output logic vld;

	typedef enum logic [1:0] {IDLE, SYNC, SHFT_LFT, SHFT_RGHT} state_t;
	state_t state, nxt_state;
	
	logic sclk_rise, ws_fall, resynch_check;	// input for state machine function
	logic clr_cnt;		// output for state machine function
	logic set_vld;

	logic [4:0] bit_cntr;
	logic eq24, eq23, eq22;
	logic [47:0] shft_reg;

	always_ff @(posedge clk, negedge rst_n) 
		if (!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;

	always_comb begin
		nxt_state = state;
		clr_cnt = 0;
		set_vld = 0;
		
		case(state)
			IDLE:
				if (ws_fall)
					nxt_state = SYNC;

			SYNC:
				if (sclk_rise) begin
					clr_cnt = 1;
					nxt_state = SHFT_LFT;
				end

			SHFT_LFT:
				if (eq24) begin
					clr_cnt = 1;
					nxt_state = SHFT_RGHT;
				end

			default: begin
				if (eq24) begin
					clr_cnt = 1;
					set_vld = 1;
					nxt_state = SHFT_LFT;
				end
				else if (resynch_check) 
					nxt_state = IDLE;
			end
		endcase
	end

	// logic for resynch check
	assign resynch_check = (eq22 && !I2S_ws && sclk_rise) || (eq23 && I2S_ws && sclk_rise);		// need to check specific at rising clock edge
																								// when eqaul to 23, first half is useless

	// logic for bit counter
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			bit_cntr <= 5'b00000; 
		else if (clr_cnt)
			bit_cntr <= 5'b00000;
		else if (sclk_rise)
			bit_cntr <= bit_cntr + 1;

	assign eq24 = (bit_cntr == 5'd24);
	assign eq23 = (bit_cntr == 5'd23);
	assign eq22 = (bit_cntr == 5'd22);

	// logic for shifter
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			shft_reg <= 48'd0;
		else if (sclk_rise)
			shft_reg <= {shft_reg[46:0],I2S_data};
	
	assign lft_chnnl = shft_reg[47:24];
	assign rght_chnnl = shft_reg[23:0];

	// logics for detecting sclk rise using two FF
	logic ff_1, ff_2, ff_11, ff_22;
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) begin
			ff_11 <= 0;
			ff_22 <= 0;
			ff_1 <= 0;
			ff_2 <= 0;
		end
		else begin
			ff_11 <= I2S_sclk;
			ff_22 <= ff_11;
			ff_1 <= ff_22;
			ff_2 <= ff_1;
		end
	assign sclk_rise = !ff_2 && ff_1;

	// logics for detecting ws fall using two FF
	logic ff_3, ff_4, ff_33, ff_44;
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) begin
			ff_33 <= 0;
			ff_44 <= 0;
			ff_3 <= 0;
			ff_4 <= 0;
		end
		else begin
			ff_33 <= I2S_ws;
			ff_44 <= ff_33;
			ff_3 <= ff_44;
			ff_4 <= ff_3;
		end
	assign ws_fall = ff_4 && !ff_3;
	
	// logics for vld
	always_ff @(posedge clk, negedge rst_n) 
		if (!rst_n)
			vld <= 0;
		else
			vld <= set_vld;	
endmodule
`default_nettype wire