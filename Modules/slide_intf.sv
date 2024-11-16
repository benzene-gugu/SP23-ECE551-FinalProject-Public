/*
 * slide_intf.sv
 *
 * Author: Yucheng Zang
 * Create: Apr 05, 23   (Ex19)
 * Revise: Apr 24, 23   (Final Project, Documentation)
 *
 * A Interface that perform round robin conversions on the various A2D channels 
 * that are connected to the slide pots, and provide the 6 potentiometer values 
 * as 12-bit unsigned numbers stored in 6 different registors 
 *
 * Spec for different bands:
 * LP (low pass, bass),             B1 (band 1, 80Hz to 280Hz), 
 * B2 (band 2, 280Hz to 1kHz),      B3 (band 3, 1kHz to 3.6Khz), 
 * HP (high pass, treble)
 *
 * Required modules:
 *  - A2D_intf.sv                   (A2D interface)
 *      - SPI_mnrch.sv              (Used to commucate with the A2D module)
 */
module slide_intf(
    input clk,                          // Clock
    input rst_n,                        // Asynch active low reset
    output SS_n,                        // SPI active low serf select
    output SCLK,                        // SPI clock
    output MOSI,                        // SPI Master out slave in (to A2D)
    input MISO,                         // SPI Master in slave out (from A2D)
    output reg [11:0] POT_LP,  // The position of low pass filter slider
    output reg [11:0] POT_B1,  // The position of band 1 filter slider
    output reg [11:0] POT_B2,  // The position of band 2 filter slider
    output reg [11:0] POT_B3,  // The position of band 3 filter slider
    output reg [11:0] POT_HP,  // The position of high pass filter slider
    output reg [11:0] VOLUME   // The position of volume slider
);

    /* <------------------- Internal Signals -------------------> */
    logic set_strt_cnv;                 // Connects to the A2D_intf's input 
                                        // 'strt_cnv', assert by the state 
                                        // machine of this module to initate a 
                                        // new A2D conversion

    logic [2:0] chnnl_reg;              // The output of this reg connects to 
                                        // the A2D_intf's input 'chnnl' to 
                                        // indicate which A2D channel to convert

    logic incr_chnnl;                   // Asserted by the state machine to 
                                        // increment the value in the chnnl_reg

    logic cnv_cmplt_A2D_intf;           // Connects to the output signal 
                                        // 'cnv_cmplt' of A2D_intf. Asserted by 
                                        // A2D_intf when a conversion is completed

    logic [11:0] res_A2D_intf;          // Connects to the output signal 'res'
                                        // of A2D_intf. Stores the result of a 
                                        // conversion when cnv_cmplt is asserted
                                        

    logic POT_LP_enable, POT_B1_enable, // Enable signal for flop POT_LP,
          POT_B2_enable, POT_B3_enable, // POT_B1, POT_B2, POT_B3, POT_HP,
          POT_HP_enable, VOLUME_enable; // and VOLUME respectively


    /* <------------------- Instantiate A2D_intf -------------------> */
    // See file 'A2D_intf.sv' for documentation on connection
    A2D_intf iA2D_intf(
                        .clk(clk),       
                        .rst_n(rst_n),
                        .strt_cnv(set_strt_cnv),
                        .cnv_cmplt(cnv_cmplt_A2D_intf),
                        .chnnl(chnnl_reg),
                        .res(res_A2D_intf),
                        .SS_n(SS_n),
                        .SCLK(SCLK),
                        .MOSI(MOSI),
                        .MISO(MISO)
                    );



    /* <------------------- Imply 'chnnl_reg' -------------------> */
    // Specify which channel needs to be converted. It will increment its value
    // when signal 'incr_chnnl' is asserted by the state machine.
    // The sequence of increment will be {0, 1, 2 ,3 ,4, 7}. Note that there is 
    // no channel 5 and 6, so a if branch is used to avoid undesired waiting in
    // clock cycle
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n)
            chnnl_reg <= 3'b000;
        else if (incr_chnnl) begin
            if (chnnl_reg == 3'b100)
                chnnl_reg <= 3'b111;
            else 
                chnnl_reg <= chnnl_reg + 1;
        end
    end



    /* <------------------- Imply The Output Flops -------------------> */
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n) 
            POT_LP <= 12'h000;
        else if (POT_LP_enable)
            POT_LP <= res_A2D_intf;
    end 

    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n) 
            POT_B1 <= 12'h000;
        else if (POT_B1_enable)
            POT_B1 <= res_A2D_intf;
    end 

    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n) 
            POT_B2 <= 12'h000;
        else if (POT_B2_enable)
            POT_B2 <= res_A2D_intf;
    end 

    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n) 
            POT_B3 <= 12'h000;
        else if (POT_B3_enable)
            POT_B3 <= res_A2D_intf;
    end 

    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n) 
            POT_HP <= 12'h000;
        else if (POT_HP_enable)
            POT_HP <= res_A2D_intf;
    end 

    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n) 
            VOLUME <= 12'h000;
        else if (VOLUME_enable)
            VOLUME <= res_A2D_intf;
    end 



    /* <------------------- The State Machine -------------------> */
    // SM input: cnv_cmplt_A2D_intf (if asserted, go from WAIT_CMPLT to 
    //           START_CONV)
    // SM outputs: set_strt_cnv (command A2D_intf to start a new conversion),
    //             incr_chnnl (assert to increment the value in 'chnnl_reg'),
    //             POT_LP_enable, POT_B1_enable, POT_B2_enable, POT_B3_enable
    //             POT_HP_enable, VOLUME_enable (Enable signals for respective 
    //             output flops)
    typedef enum logic { START_CONV, WAIT_CMPLT } state_t;
    state_t state, next_state;

    // Imply the state flop
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n)
            state <= START_CONV;
        else 
            state <= next_state;
    end


    // State machine combination logic
    always_comb begin
        // Use default values to avoid latches
        next_state = state;
        set_strt_cnv = 1'b0;
        incr_chnnl = 1'b0;

        POT_LP_enable = 1'b0;
        POT_B1_enable = 1'b0;
        POT_B2_enable = 1'b0; 
        POT_B3_enable = 1'b0;
        POT_HP_enable = 1'b0; 
        VOLUME_enable = 1'b0;

        case (state) 
            START_CONV : begin
                // Command the A2D_intf to start a new conversion, and transition
                // to WAIT_CMPLT waiting for the 'cnv_cmplt_A2D_intf' signal to 
                // be asserted
                set_strt_cnv = 1'b1;
                next_state = WAIT_CMPLT;
            end

            WAIT_CMPLT : begin
                // Wait here until signal 'cnv_cmplt_A2D_intf' is asserted by the
                // A2D_intf
                // If 'cnv_cmplt_A2D_intf' is asserted, turn on the respective 
                // output flop's enable signal according to the value in 
                // 'chnnl_reg', then assert 'incr_chnnl' to command 'chnnl_reg' 
                // incrementing the value
                if (cnv_cmplt_A2D_intf) begin
                    case (chnnl_reg) 
                        3'b000 : POT_B1_enable = 1'b1;
                        3'b001 : POT_LP_enable = 1'b1;
                        3'b010 : POT_B3_enable = 1'b1;
                        3'b011 : POT_HP_enable = 1'b1;
                        3'b100 : POT_B2_enable = 1'b1;
                        default : VOLUME_enable = 1'b1;
                    endcase

                    incr_chnnl = 1'b1;
                    next_state = START_CONV;
                end
            end
        endcase
    end
endmodule