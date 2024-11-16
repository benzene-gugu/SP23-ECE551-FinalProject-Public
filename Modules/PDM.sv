module PDM (clk, rst_n, duty, PDM, PDM_n);
  input clk, rst_n;
  input [15:0] duty;
  output reg PDM, PDM_n;
  
  logic [15:0] subtract, add, subtract_B;
  logic A_compare_B;
  logic [15:0] duty_q, add_q; 

  // sequential part FF
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      duty_q <= 0;
    else
      duty_q <= duty;
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      add_q <= 0;
    else
      add_q <= add;
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      PDM <= 1'b0;
      PDM_n <= 1'b1;
    end
    else begin
      PDM <= A_compare_B;
      PDM_n <= ~A_compare_B;
    end
  end

  // comb circuit

  assign subtract_B = (A_compare_B) ? 16'hffff : 16'h0000;
  assign subtract = subtract_B - duty_q;
  assign add = add_q + subtract;
  assign A_compare_B = (duty_q > add_q || duty_q == add_q) ? 1'b1 : 1'b0;

endmodule
