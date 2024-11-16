/*
 * A2D_intf.sv
 *
 * This module uses the SPI Monarch (SPI_mnrch.sv) to interface with the A2D 
 * converter on the DE0-Nano board. 
 * 
 * This module abstracts the detail about SPI interface so that the user of this
 * module only need to choose a channel and assert a start conversion signal
 *
 * NOTE: before cnv_cmplt is asserted, res[11:0] would contain garbage
 */
module A2D_intf (
    input clk,              // Clock
    input rst_n,            // Asynch active low reset
    input strt_cnv,         // Assert for at least one clock cycle to start a 
                            // conversioin
    output reg cnv_cmplt,   // Asserted by A2D_intf to indicate the conversion
                            // has completed, and stays asserted til the next 
                            // strt_cnv assertion
    input [2:0] chnnl,      // Specifies which A2D channel (0~7) to convert
    output [11:0] res,      // The 12-bit result from the A2D (lower 12-bits 
                            // read from SPI)
    output SS_n,            // SPI active low serf select
    output SCLK,            // SPI clock
    output MOSI,            // SPI Master out slave in (to A2D)
    input MISO              // SPI Master in slave out (from A2D)
);

    /* <------------------- Internal logics -------------------> */
    logic set_snd;                  // Use to set the 'snd' signal on SPI_mnrch
    logic set_cnv_cmplt;            // Use to set the 'cnv_cmplt' flop
    logic done_SPI_mnrch;           // Gets signal from 'done' on SPI_mnrch
    logic [15:0] temp_res;

    assign res = temp_res[11:0];


    /* <--------- Instantiate SPI_mnrch & Configure Its Dataflow ---------> */
    SPI_mnrch iSPI_mnrch (
        .clk(clk),                              // Shares the same clock
        .rst_n(rst_n),                          // Shares the same reset
        .SS_n(SS_n),                            // Serf Select
        .SCLK(SCLK),                            // SPI Clock
        .MOSI(MOSI),                            // Master out slave in
        .MISO(MISO),                            // Master in slave out
        .snd(set_snd),                          // Assert when send command
        .cmd({2'b00, chnnl[2:0], 11'h000}),     // Convert the user-specified 
                                                // channel number to the SPI
                                                // command that's been sent to 
                                                // the A2D
        .done(done_SPI_mnrch),                  // Asserted by SPI_mnrch when a 
                                                // conversion is finished
        .resp(temp_res)                              // Conversion result
    );
    


    /* <------------------- Imply cnv_cmplt flop -------------------> */
    // This flop will be set to 1 when set_cnv_cmplt is asserted, and will be 
    // reset to 0 when strt_cnv is asserted
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n) 
            cnv_cmplt <= 1'b0;
        else begin
            if (set_cnv_cmplt) 
                cnv_cmplt <= 1'b1;
            else if (strt_cnv) 
                cnv_cmplt <= 1'b0;
        end
    end

    

    /* <------------------- State Machine -------------------> */
    // SM inputs: strt_cnv (from outside), done_SPI_mnrch (from SPI_mnrch)
    // SM outputs: set_snd (internet, which is connected to 'snd' of SPI_mnrch),
    // set_cnv_cmplt (internal, will set cnv_cmplt flop to 1)

    typedef enum logic[1:0] { IDLE, SEND_CHANNEL, WAIT_1_CLK, RECEIVE_RESULT } state_t;
    state_t state, next_state;

    // Imply the state flop
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else 
            state <= next_state;
    end

    // State machine combination logic
    always_comb begin
        // Use default values to avoid latches
        next_state = state;
        set_snd = 1'b0;
        set_cnv_cmplt = 1'b0;

        case (state) 
            IDLE : begin
                // If strt_cnv is asserted, assert signal 'set_snd' and go to 
                // state 'SEND_CHANNEL'
                if (strt_cnv) begin
                    set_snd = 1'b1;
                    next_state = SEND_CHANNEL;
                end
            end

            SEND_CHANNEL: begin
                // The state machine will stay in this stay until signal 
                // 'done_SPI_mnrch' is asserted. When it is asserted, go to next 
                // state 'WAIT_1_CLK' to wait for 1 clock cycle. This is due to
                // the requirement of the A2D convert on the board. It needs one 
                // clock cycle gap between each SPI transcation
                if (done_SPI_mnrch) 
                    next_state = WAIT_1_CLK;
            end

            WAIT_1_CLK: begin
                // The amount of time between each state transition is 1 clock 
                // cycle, so after this state is reached, it will set 'set_snd' 
                // and leave this state unconditionally at the next clock period
                set_snd = 1'b1;
                next_state = RECEIVE_RESULT;
            end

            RECEIVE_RESULT: begin
                // Like it was in state 'SEND_CHANNEL', the he state machine 
                // will also stay in this stay until signal 'done_SPI_mnrch'
                // is asserted. When it is asserted, assert 'set_cnv_cmplt' to
                // set flop 'cnv_cmplt' to 1. This flop will continue to be 1 
                // until 'strt_cnv' (from ouside) is asserted again 
                if (done_SPI_mnrch) begin
                    set_cnv_cmplt = 1'b1;
                    next_state = IDLE;
                end
            end

        endcase

    end

endmodule