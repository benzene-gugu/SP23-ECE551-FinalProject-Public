module snd_cmd_tb();

logic	clk, rst_n, snd, resp_rcvd, initialized;
logic	RX, TX;
logic [4:0]	cmd_start;
logic [3:0]	cmd_len;


// snd_cmd intilization
snd_cmd		iDUT(.clk(clk), 
.rst_n(rst_n), 
.send(snd), 
.cmd_start(cmd_start),
 .cmd_len(cmd_len),
.RX(RX), 
.TX(TX),
 .resp_rcvd(resp_rcvd));
 
// intilization of RN52_cmd_model
RN52_cmd_model	iRN52(.clk(clk), .rst_n(rst_n), .initialized(initialized), .RX(TX), .TX(RX));



initial begin
   clk = 1'b0;
   rst_n = 1'b0;
   snd = 1'b0;
   cmd_start = 1'b0;
   cmd_len = 1'b0;
   
   // "S|,01\r"
   cmd_start = 5'b00000;
   cmd_len = 4'b0110;
   @(posedge clk);
   @(negedge clk)
   rst_n = 1'b1;
   @(negedge clk) 
   snd = 1'b1;
   @(negedge clk) 
   snd = 1'b0; // snd set at negedge

   //  "SN,EQ-551\r"
   @(posedge resp_rcvd);
   repeat (2) @(posedge clk);
   cmd_start = 5'b00110;
   cmd_len = 4'b1010;
   
   @(negedge clk) 
   snd = 1'b1;
   @(negedge clk) 
   snd = 1'b0;
   fork
      begin: TIMEOUT	// timeout if after 50000 clk cycles intilization is sill not asserted
         repeat (50000) @(posedge clk);
         $display("Command 1&2 TIMEOUT!");
         $stop();
      end
      begin		
         @(posedge initialized);
         disable TIMEOUT;
         $display("Command 1&2 ASSERTED!");
		 $stop();
      end
   join
end


// clk generation
always	#5 clk <= ~clk;


endmodule
