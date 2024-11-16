/*
 * low_freq_queue_tb.sv
 *
 * Author: Yucheng Zang
 * Create: Apr 18, 23 (HW 5)
 *
 * Passed: Tue Apr 18 5:27 PM       (Test 1)
 * Passed: Wed Apr 19 0:39 PM       (Test 2)
 * Passed: Wed Apr 19 2:39 PM       (Test 3)
 *
 * Non-self-checking testbench for low_freq_queue
 *
 * Required modules:
 *  - low_freq_queue.sv                 (iDUT)
 *      - rise_edge_detector.sv         (Required by iDUT)
 *      - prescalar_2_to_1.sv           (Required by iDUT)
 *      - dualPort1024x16.v             (Required by iDUT)
 */
module low_freq_queue_tb ();
    // Internal logics
    logic clk;
    logic rst_n;

    // Stimulus signals
    logic [15:0] lft_smpl_stim;         // Used to read test data in to the queue
    logic [15:0] rght_smpl_stim;        // Used to read test data in to the queue
    logic wrt_smpl_stim;                // Pull to high when intend to wirte data
                                        // in

    // Monitor signals
    logic [15:0] lft_out_mon;           // Used to monitor the data comming out 
                                        // from the queue
    logic [15:0] rght_out_mon;          // Used to monitor the data comming out 
                                        // from the queue
    logic sequencing_mon;               // Should be out when data is wrtting out


    // Instantiate iDUT
    low_freq_queue iDUT (
                        .clk(clk),
                        .rst_n(rst_n),
                        .lft_smpl(lft_smpl_stim),
                        .rght_smpl(rght_smpl_stim),
                        .wrt_smpl(wrt_smpl_stim),
                        .lft_out(lft_out_mon),
                        .rght_out(rght_out),
                        .sequencing(sequencing_mon)
                        );
    

    // Create clock
    always 
        #5 clk = ~clk;


    // Start driving the test
    initial begin
        // Initial setup
        clk = 1'b0;
        lft_smpl_stim = 10'd0;
        rght_smpl_stim = 10'd0;
        wrt_smpl_stim = 1'b0;


        // // Reset iDUT
        // @ (posedge clk) rst_n = 1'b0;
        // @ (negedge clk) rst_n = 1'b1;


        // // Test 1: 
        // //  Use a for loop, continuesly write the circular queue
        // // Stimulus:
        // //  For every 10 clock cycles,
        // //      - assert 'wrt_smpl_stim'
        // //      - increment 'lft_smpl_stim' and 'rght_smpl_stim' by 1
        // // Observe:
        // //  - 'sequencing' should remain LOW
        // //  - 'lft_out_mon' and 'rght_out_mon' should NOT change
        // for (lft_smpl_stim = 0; lft_smpl_stim < 500; lft_smpl_stim ++) begin
        //     // Sync left with right
        //     rght_smpl_stim = lft_smpl_stim;

        //     // For every 10 clock cycles, assert 'wrt_smpl_stim'
        //     repeat(9) @ (posedge clk);
        //     wrt_smpl_stim = 1'b1;
            
        //     @ (posedge clk);
        //     wrt_smpl_stim = 1'b0;
        // end


        // Reset iDUT
        @ (posedge clk) rst_n = 1'b0;
        @ (negedge clk) rst_n = 1'b1;


        // Test 2: 
        //  Use a for loop, continuesly write 2040 pairs of data the circular queue
        // Stimulus:
        //  For every 10 clock cycles,
        //      - assert 'wrt_smpl_stim'
        //      - increment 'lft_smpl_stim' and 'rght_smpl_stim' by 1
        // Observe:
        //  Since the 'low_freq_queue' reads a new data in every other rising 
        //  edge of 'wrt_smpl', so the queue should store every other number,
        //  i.e. {1, 3, 5, 7, 9, ...}
        //  - When the 'sequencing' signal eventually goes high, check the output
        //    of the queue
        //  - Check the data output
        for (lft_smpl_stim = 0; lft_smpl_stim < 2042; lft_smpl_stim ++) begin
            // Sync left with right
            rght_smpl_stim = lft_smpl_stim;

            // For every 10 clock cycles, assert 'wrt_smpl_stim'
            repeat(9) @ (posedge clk);
            wrt_smpl_stim = 1'b1;
            
            @ (posedge clk);
            wrt_smpl_stim = 1'b0;
        end

    
        // Wait when sequencing goes low
        @ (negedge sequencing_mon);


        // Test 3: 
        //  Continue add one more pair of data
        // Observe:
        //  - When the 'sequencing' signal eventually goes high, check the output
        //    of the queue
        //  - Check the data output
        //  - Check if the pointers wraps around correctly

        // Assert new sample
        lft_smpl_stim = 2041;
        rght_smpl_stim = 2041;

        // Wait 9 clock cycles, same as Test 1 and 2
        repeat(9) @ (posedge clk);

        // Assert wrt_smpl_stim for 1 clock cycle
        @ (posedge clk) wrt_smpl_stim = 1'b1;
        @ (posedge clk) wrt_smpl_stim = 1'b0;

        // Wait when sequencing goes low
        @ (negedge sequencing_mon);

        $stop;
    end

    
endmodule