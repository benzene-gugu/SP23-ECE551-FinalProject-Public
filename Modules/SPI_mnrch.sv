/*
 * SPI_mnrch.sv
 * 
 * Signals:
 * clk		:	50MHz system clock	(in)
 * cst_n	:	reset				(in)
 * SS_n		:	Chip select			(out)
 * SCLK		:	SPI clock			(out)
 * MOSI		:	Master Out Slave In	(out)
 * MISO		:	Master In Slave Out	(in)
 * snd		:	high for 1 clock period would initiate a SPI transcation (in)
 * cmd 		:	16-bit command being sent to inertial sensor (in)
 * done		:	Assert when an SPI transcation is complete, and stay high until
 *				next wrt (out)
 * resp		:	16-bit data from the SPI serf. For inertial sensor we will only 
 *				use bit [7:0] (out)
 */
module SPI_mnrch (
	input clk, 			// Clock
	input rst_n, 		// Active-low reset
	output SS_n, 		// Chip select
	output SCLK, 		// SPI clock
	output MOSI, 		// Master out slave in
	input MISO, 		// Master in slave out
	input snd, 			// high for 1 clock period will initiate a SPI transcation
	input [15:0] cmd, 	// 16-bit command being sent to inertial sensor
	output done, 		// Assert when an SPI transcation is complete, and stay 
						// high until next wrt
	output [15:0] resp	// 16-bit data from the SPI serf. For inertial sensor we
						// will only use bit [7:0]
	);
		
	
	/* <--------------- SCLK_div logic ---------------> */
	// Internal signals for SCLK_div logic
	logic ld_SCLK;					// Load the SCLK_div with new value (5'b1011)
	logic full;						// Assert when SCLK_div stores all 1
	logic shft;						// Assert when it's the time to shift the 
									// shift register
	logic [4:0] SCLK_div_flop;		// The flopped value of SCLK_div
		  
	// Imply the SCLK_div flop.
	// If ld_SCLK is asserted, this flop is preseted to 5'b10111, else, it will
	// increment itself
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n) 
			SCLK_div_flop <= 5'b10111;		// 5'b00000
		else 
			SCLK_div_flop <= ld_SCLK ? 5'b10111 : SCLK_div_flop + 1;
	end
	
	// The output of the SCLK_div subsystem
	assign SCLK = SCLK_div_flop[4];		// SCLK (1/32 pre-scaled version of clk) 
										// is the MSB of the value stored in 
										// the SCLK_div flop
	assign full = &SCLK_div_flop;		// Assert true if SCLK_div = 5'b11111
	assign shft = (SCLK_div_flop == 5'b10001) ? 1'b1 : 1'b0;	// Time to shift
											
	
	
	/* <--------------- bit_cntr ---------------> */
	// Internal signals for bit_cntr
	logic [4:0] bit_cntr_flop;		// The flopped value of bit_cntr
	logic done16;					// Assert if all 16 bits were sent
	logic init;						// When asserted, the circuit will be 
									// initialized
	
	// Imply the bit_cntr flop
	// If init is asserted, bit_cntr_flop will get value 5'b00000; else, if 
	// depending on the value of shft. If shft is high, it will increment by 1, 
	// else it will maintain itself
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n) 
			bit_cntr_flop <= 5'b00000;
		else 
			bit_cntr_flop <= init ? 5'b00000 :
							(shft ? bit_cntr_flop + 1 : bit_cntr_flop);
	end
	
	// The combinational logic for the output
	assign done16 = (bit_cntr_flop == 5'b10000);
	
	

	/* <--------------- Shift registers ---------------> */
	// Internal signals for shfit regesters
	logic [15:0] shft_reg_input;
	logic [15:0] shft_reg;
	
	// Infer the shift register
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n) 
			shft_reg <= 16'h0000;
		else 
			shft_reg <= shft_reg_input;
	end
	
	// Infer the combinational logic which determines the shft_reg_input
	always_comb begin
		case({init, shft})
			2'b00 	:	shft_reg_input = shft_reg;
			2'b01	:	shft_reg_input = {shft_reg[14:0], MISO};
			default	:	shft_reg_input = cmd;
		endcase
	end

	// The MSB of the shift register is just the MOSI 
	assign MOSI = shft_reg[15];
	
	// The resp (response) will be the shift register. However, before done is 
	// asserted, the value would be garbage
	assign resp = shft_reg;
	
	
	
	/* <--------------- State machine ---------------> */
	// SM inputs: snd, done16, full
	// SM outputs: ld_SCLK, , set_done, shft, SS_n
	// Internal logics for the state machine
	typedef enum logic [1:0] {IDLE, SHIFT, BACK_PORCH} state_t;
	state_t state, next_state;

	logic set_done;				// Use to generate done_flopped
	
	logic SS_n_flopped, done_flopped;	// Flop SS_n and done to avoid glitch

	// SS_n_flopped 
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)
			SS_n_flopped <= 1'b1;
		else 
			SS_n_flopped <= set_done & ~init;
	end

	assign SS_n = SS_n_flopped;

	// done_flopped
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)
			done_flopped <= 1'b0;
		else 
			done_flopped <= set_done & ~init;
	end

	assign done = done_flopped;
	
	// State flop
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)
			state <= IDLE;
		else 
			state <= next_state;
	end

	// State machine combination logic
	always_comb begin
		// Use default values to avoid latches
		next_state = state;
	
		init = 1'b0;
		ld_SCLK = 1'b1;
		set_done = done_flopped; // 1'b0;		
		
		case (state)
			IDLE : begin
				// If signal 'snd' is asserted, initialize the circuit and 
				// transition to the SHIFT state, else, continue asserting ld_SCLK
				// to pull up SCLK
				if (snd) begin
					init = 1'b1;
					ld_SCLK = 1'b0;
					next_state = SHIFT;
				end
			end

			SHIFT : begin
				// We don't want to load clock while tranceiving
				ld_SCLK = 1'b0;
				// If all 16 bits of data are sent, go to generate the back porch
				if (done16)
					next_state = BACK_PORCH;
			end

			BACK_PORCH : begin
				
				ld_SCLK = 1'b0;	

				if (full) begin
					// Go back to IDLE state after one transcation is completed
					ld_SCLK = 1'b1;
					set_done = 1'b1;
					next_state = IDLE;
				end
			end

			default : next_state = IDLE;

		endcase
		
	end
	
endmodule