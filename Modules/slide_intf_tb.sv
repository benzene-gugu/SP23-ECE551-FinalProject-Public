/*
 * slide_intf_tb.sv
 *
 * A testbench for the slide_intf
 */
module slide_intf_tb();
    logic clk;
    logic rst_n;

    // Interconnction buses
    logic SS_n_bus, SCLK_bus, MOSI_bus, MISO_bus;

    // DUT Monitor signals
    logic [11:0] POT_LP_mon, POT_B1_mon, POT_B2_mon, POT_B3_mon, POT_HP_mon,
                 VOLUME_mon;
    
    // slide_intf stims
    logic [11:0] LP_stim, B1_stim, B2_stim, B3_stim, HP_stim, VOL_stim;

    // Instantiate the A2D_with_Pots and A2D_intf
    A2D_with_Pots iPots(
                        .clk(clk),
                        .rst_n(rst_n),
                        .SS_n(SS_n_bus),
                        .SCLK(SCLK_bus),
                        .MISO(MISO_bus),
                        .MOSI(MOSI_bus),
                        .LP(LP_stim),
                        .B1(B1_stim),
                        .B2(B2_stim),
                        .B3(B3_stim),
                        .HP(HP_stim),
                        .VOL(VOL_stim)
                        );

    slide_intf iDUT(
                    .clk(clk),
                    .rst_n(rst_n),
                    .SS_n(SS_n_bus),
                    .SCLK(SCLK_bus),
                    .MISO(MISO_bus),
                    .MOSI(MOSI_bus),
                    .POT_LP(POT_LP_mon),
                    .POT_B1(POT_B1_mon),
                    .POT_B2(POT_B2_mon),
                    .POT_B3(POT_B3_mon),
                    .POT_HP(POT_HP_mon),
                    .VOLUME(VOLUME_mon)
                    );


    // Create clock
    always 
        #5 clk = ~clk;
    
    initial begin
        clk = 1'b0;

        @ (posedge clk) rst_n = 1'b0;           // Assert rst_n
        @ (negedge clk) rst_n = 1'b1;           // De-Assert rst_n

        // Hard-code fixed value for pots
        LP_stim = 12'h000;
        B1_stim = 12'h001;
        B2_stim = 12'h010;
        B3_stim = 12'h100;
        HP_stim = 12'h111;
        VOL_stim = 12'h400;

        // Wait for 1000 clock cycles, and check the result
        repeat (15000) @ (posedge clk);

        // Test A-1
        if (POT_LP_mon !== 12'h000) begin
            $display("Test A-1 Failed: POT_LP_mon is expected %h, yet %h is ",
                      "observed", 12'h000, POT_LP_mon);
            $stop;
        end
        $display("Test A-1 Passed");

        // Test A-2
        if (POT_B1_mon !== 12'h001) begin
            $display("Test A-2 Failed: POT_B1_mon is expected %h, yet %h is ",
                      "observed", 12'h001, POT_B1_mon);
            $stop;
        end
        $display("Test A-2 Passed");

        // Test A-3
        if (POT_B2_mon !== 12'h010) begin
            $display("Test A-3 Failed: POT_B2_mon is expected %h, yet %h is ",
                      "observed", 12'h010, POT_B2_mon);
            $stop;
        end
        $display("Test A-2 Passed");

        // Test A-4
        if (POT_B3_mon !== 12'h100) begin
            $display("Test A-4 Failed: POT_B3_mon is expected %h, yet %h is ",
                      "observed", 12'h100, POT_B3_mon);
            $stop;
        end
        $display("Test A-3 Passed");

        // Test A-5
        if (POT_HP_mon !== 12'h111) begin
            $display("Test A-5 Failed: POT_HP_mon is expected %h, yet %h is ",
                      "observed", 12'h111, POT_HP_mon);
            $stop;
        end
        $display("Test A-4 Passed");

        // Test A-6
        if (VOLUME_mon !== 12'h400) begin
            $display("Test A-6 Failed: VOLUME_mon is expected %h, yet %h is ", 
                      "observed", 12'h400, VOLUME_mon);
            $stop;
        end
        $display("Test A-5 Passed");

        $display("Yahoo! All test passed");
        $stop();
    end

endmodule