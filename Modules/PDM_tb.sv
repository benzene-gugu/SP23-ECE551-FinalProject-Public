module PDM_tb ();
  logic clk, rst_n;
  logic [15:0] duty_sim;
  reg PDM, PDM_n;
  
  PDM iDUT (.clk(clk), .rst_n(rst_n), .duty(duty_sim), .PDM(PDM), .PDM_n(PDM_n));
  
  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    duty_sim = 16'h0000;
 
    @(negedge clk) rst_n = 1'b1;
    // 100% duty cycle
    @(posedge clk) duty_sim = 16'hFFFF;
    repeat (65536) @(posedge clk);
    
    // 75% duty cycle
    @(posedge clk) duty_sim = 16'hC000;
    repeat (16) @(posedge clk);
 
    // 50% duty cycle
    @(posedge clk) duty_sim = 16'h8000;
    repeat (10) @(posedge clk);

    // 33% duty cycle
    @(posedge clk) duty_sim = 16'h5555;
    repeat (9) @(posedge clk);

    // 25% duty cycle
    @(posedge clk) duty_sim = 16'h4000;
    repeat (12) @(posedge clk);

    // 1% duty cycle
    @(posedge clk) duty_sim = 16'h028F;
    repeat (2400) @(posedge clk);
    $stop();
  end

  always
    #5 clk = ~clk;
endmodule
