/*
 * rise_edge_detector_tb.sv
 *
 * Author: Yucheng Zang
 * Create: Apr 17, 23 (HW 5)
 *
 * Passed: Monday Apr 17 4:06 PM    (Test 1, 2, 3, 4)
 * Passed: Monday Apr 17 4:58 PM    (Test 0)
 *
 * Testbench for rise_edge_detector
 *  - NOT required by Hoffman
 *  - NOT self-checking
 *
 * Required modules:
 *  - rise_edge_detector.sv             (iDUT)
 */
module rise_edge_detector_tb(); 
    logic clk;
    logic rst_n;

    logic signal_stim;              // Stimulus
    logic rise_edge_mon;            // Monitor

    // Instantiate iDUT
    rise_edge_detector iDUT (
                            .clk(clk),
                            .rst_n(rst_n),
                            .signal(signal_stim),
                            .rise_edge(rise_edge_mon)
                            );

    // Create clock
    always 
        #5 clk = ~clk;

    initial begin
        // Initial setup
        clk = 1'b0;
        signal_stim = 1'b0;

        // Reset 
        @ (posedge clk) rst_n = 1'b0;
        @ (negedge clk) rst_n = 1'b1;

        // Test 0: assert a 1-clock-long HIGH
        @ (posedge clk) signal_stim = 1'b1;
        @ (posedge clk) signal_stim = 1'b0;

        // Wait 5 clock cycles and try again
        repeat (5) @ (posedge clk); 

        @ (posedge clk) signal_stim = 1'b1;
        @ (posedge clk) signal_stim = 1'b0;

        // Wait 5 clock cycles then countinue
        repeat (5) @ (posedge clk); 
        
        // Test 1: assert a 5-clock-long HIGH
        repeat(5) @ (posedge clk) signal_stim = 1'b1;
        @ (posedge clk) signal_stim = 1'b0;

        // Test 2: assert a 10-clock-long HIGH
        repeat(10) @ (posedge clk) signal_stim = 1'b1;
        repeat(2) @ (posedge clk) signal_stim = 1'b0;

        // Test 3: assert a 15-clock-long HIGH
        repeat(15) @ (posedge clk) signal_stim = 1'b1;
        repeat(5) @ (posedge clk) signal_stim = 1'b0;

        // Test 4: assert a 20-clock-long HIGH
        repeat(20) @ (posedge clk) signal_stim = 1'b1;
        @ (negedge clk) signal_stim = 1'b0;

        $stop;
    end

endmodule