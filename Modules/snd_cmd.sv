module snd_cmd(clk, rst_n, cmd_start, send, cmd_len, resp_rcvd, RX, TX);
	input clk;
	input rst_n;
	input [4:0] cmd_start;
	input send;
	input [3:0] cmd_len;
	output resp_rcvd;
	input RX;
	output TX;
	
	// intermediate addr into cmdROM
	logic [4:0] addr;
	logic [4:0] check;
	logic inc_addr; // output of state machine: controlled by the state machine
	logic [7:0] tx_data;
	logic [4:0] sum; // intim var to store something
	logic last_byte;
	
	logic [7:0] rx_data;
	logic rx_rdy;
	logic clr_rx_rdy;
	logic trmt;
	logic tx_done;
	
	typedef enum reg [1:0] {IDLE, WAIT, TRANSMIT, LASTBYTE} state_t;
	state_t state, nxt_state;
	
	// temp variable storage
	//assign sum = cmd_start + cmd_len;
	
	
	// comb logic for control the logic into cmdROM
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			addr <= 5'b00000;
		else if(send)
			addr <= cmd_start;
		else if(inc_addr)
			addr <= addr + 1'b1;
	end

	// cmdROM control logic
	cmdROM iCMDROM(.clk(clk), .addr(addr), .dout(tx_data));
	
	// comb logic for control logic check equality
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			check <= 5'b00000;
		else if(send)
			check <= cmd_start + cmd_len;
	
	end
	
	assign last_byte = (check == addr) ? 1'b1 : 1'b0;
	assign clr_rx_rdy = rx_rdy;
	// UART control logic
	UART iUART(.clk(clk), .rst_n(rst_n),.RX(RX),.TX(TX), .rx_rdy(rx_rdy),.clr_rx_rdy(clr_rx_rdy),.rx_data(rx_data),.trmt(trmt),.tx_data(tx_data),.tx_done(tx_done));
	
	assign resp_rcvd = (rx_rdy && (rx_data == 8'h0A)) ? 1'b1 : 1'b0;
	
	// state FF logic
	always_ff @(posedge clk or negedge rst_n) begin
	  if (!rst_n)
		state <= IDLE;
	  else
		state <= nxt_state;
	end
	
	// STATE MACHINE
	always_comb begin
		nxt_state = state;
		inc_addr = 0;
		trmt = 0;
		
		case(state)
			IDLE: begin
				if(send)
					nxt_state = WAIT;
			
			end
			
			TRANSMIT: begin
				trmt = 1;
				inc_addr = 1;
				nxt_state = LASTBYTE;
			
			
			end
			
			WAIT: begin
				nxt_state = TRANSMIT;
			
			end
			
			LASTBYTE : begin //LASTBYTE
			if(tx_done) begin
				if(last_byte) begin
					nxt_state = IDLE;
				end
				else begin
					nxt_state = TRANSMIT;
				end
			end
		
			end
			
			default:
				nxt_state = IDLE;
		
		
		endcase
	
	
	end


endmodule