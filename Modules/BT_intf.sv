`default_nettype none
module BT_intf(clk, rst_n, next_n, prev_n, RX, TX, cmd_n);
	input logic clk, rst_n;
	input logic next_n, prev_n;
	input logic RX;
	output logic TX;
	output logic cmd_n;
	
	// outputs of state machine
	logic [4:0] cmd_start;
	logic send;
	logic [3:0] cmd_len;

	// inputs of state machine
	logic resp_rcvd;
	logic pb1;
	logic pb2;
	logic equal_17;

	PB_release button1 (.PB(next_n), .clk(clk), .rst_n(rst_n), .released(pb1));
	PB_release button2 (.PB(prev_n), .clk(clk), .rst_n(rst_n), .released(pb2));
	snd_cmd iSEND(.clk(clk), .rst_n(rst_n), .cmd_start(cmd_start), .send(send), .cmd_len(cmd_len), .resp_rcvd(resp_rcvd), .RX(RX), .TX(TX));
	
	// 17 bit counter
	logic [16:0] cntr_17;
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			cntr_17 <= '0;
		else
			cntr_17 <= cntr_17 + 1;
	assign equal_17 = (cntr_17 == '1);
	
	// SM
	typedef enum reg [2:0] {IDLE, WAIT17, INIT1, INIT2, LISTEN} state_t;
	state_t state, nxt_state;
	
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;

	always_comb begin
		// default outputs of SM
		send = 0;
		cmd_start = 5'b00000;
		cmd_len = 4'b0000;
		cmd_n = 0;
		nxt_state = state;

		case (state)
			IDLE:
				if (!equal_17) begin
					cmd_n = 1;
					nxt_state = IDLE;
				end
				else begin
					cmd_n = 0;
					nxt_state = WAIT17;
				end
			
			WAIT17:
				if (resp_rcvd) begin
					send = 1;
					cmd_start = 5'b00000;
					cmd_len = 4'd6;
					nxt_state = INIT1;
				end

			INIT1:
				if (resp_rcvd) begin
					send = 1;
					cmd_start = 5'b00110;
					cmd_len = 4'd10;
					nxt_state = INIT2;
				end

			INIT2:
				if (resp_rcvd)
					nxt_state = LISTEN;

			default:
				if (pb1) begin
					send = 1;
					cmd_start = 5'b10000;
					cmd_len = 4'd4;
					nxt_state = LISTEN;
				end
				else if (pb2) begin
					send = 1;
					cmd_start = 5'b10100;
					cmd_len = 4'd4;
					nxt_state = LISTEN;
				end
					
		endcase
	end

endmodule
`default_nettype wire