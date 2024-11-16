/*
 * prescalar_2_to_1_tb.sv
 *
 * Author: Yucheng Zang
 * Create: Apr 17, 23 (HW 5)
 *
 * Passed: Monday Apr 17 4:31 PM    (Test 1, 2)
 *
 * Testbench for prescalar_2_to_1
 *  - NOT required by Hoffman
 *  - NOT self-checking
 *
 * Required modules:
 *  - prescalar_2_to_1.sv             (iDUT)
 *    - rise_edge_detector.sv         (Required by iDUT)
 */
module prescalar_2_to_1_tb();
    logic clk;
    logic rst_n;

    logic raw_signal_stim;              // Stimulus
    logic prescaled_signal_mon;         // Monitor

    // Instantiate iDUT
    prescalar_2_to_1 iDUT (
                            .clk(clk),
                            .rst_n(rst_n),
                            .raw_signal(raw_signal_stim),
                            .prescaled_signal(prescaled_signal_mon)
                            );


    // Create clock
    always 
        #5 clk = ~clk;


     initial begin
        // Initial setup
        clk = 1'b0;
        raw_signal_stim = 1'b0;

        // Reset 
        @ (posedge clk) rst_n = 1'b0;
        @ (negedge clk) rst_n = 1'b1;

        // Test 1: raw_signal_stim will go HIGH for 4 clock cycles, then go LOW 
        // for another 4 clock cycles. Repeat for 4 times 
        // Check: check if prescaled_signal_mon goes high for every 8 clock cycles
        repeat (4) begin
            repeat (4) @ (posedge clk) raw_signal_stim = 1'b1;
            repeat (4) @ (negedge clk) raw_signal_stim = 1'b0;
        end

        // Test 2: raw_signal_stim will go HIGH for 8 clock cycles, then go LOW 
        // for another 4 clock cycles. Repeat for 4 times 
        // Check: check if prescaled_signal_mon goes high for every 8 clock cycles
        repeat (4) begin
            repeat (8) @ (posedge clk) raw_signal_stim = 1'b1;
            repeat (8) @ (negedge clk) raw_signal_stim = 1'b0;
        end

        $stop;
     end

endmodule