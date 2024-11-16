/*
 * LED_drv
 *
 * Author: Yucheng Zang
 * Create: Apr 25, 23   (Final Project)
 *
 * A driver for the 8 LEDs on the DE-Nano board. 
 * 
 * The 8 LEDs are configured as digital audio level meters. 
 *
 * Required modules: 
 *  - sqrt.sv                       (Square root calculator, used to calculate 
 *                                   the square root of audio_in)
 */
module LED_drv (
    input clk,                      // Clock
    input rst_n,                    // Async actively low reset
    input [15:0] audio_in,          // Audio signal input
    input valid,                    // 'vld' signal from I2S_Serf
    output logic [7:0] LED          // The output to the LEDs
);



    /* <------------------- Internal Logics -------------------> */
    logic set_go;                   // Assert by state machine to init a new 
                                    // square root calculation 
    logic [7:0] sqrt_result;        // The calculation result from square root 
                                    // calculator
    logic sqrt_done;                // Connects to the 'done' signal of the 
                                    // square root calculator
    logic [23:0] counter;           // To control the LED update once per 0.25 sec
    logic timer_done;
    logic timer_clr;



    /* <----------- Instantiate the Square Root Calculator -----------> */
    // A square root calculator is used, to map the 16-bit audio signal input
    // into the 8-bit LED signals output logarithmically
    sqrt iSqrt (
                .mag(audio_in),
                .go(set_go),
                .clk(clk),
                .rst_n(rst_n),
                .sqrt(sqrt_result),
                .done(sqrt_done)
                );

    
    /* <------------------- Imply the 'counter' Flop -------------------> */
    // 24'hBEBC20 = Dec. 12,500,000, which is the amount of clock tick for 
    // 0.25 sec on a 50 Mhz clk
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n)
            counter <= 24'hBEBC20;
        else begin
            if(timer_clr)
                counter <= 24'hBEBC20;
            
            if (counter != 24'h000000)
                counter <= counter - 1;
        end
    end

    assign timer_done = ~|counter;



    /* <------------------- Imply the Output 'LED' Flop -------------------> */
    // Hold its value until a new calculation is finished by the square root 
    // calculator. Before the calculation is finished, the output of 'sqrt' may
    // contain garbage
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n) 
            LED <= 8'b0000_0000;
        if (sqrt_done) 
            LED <= sqrt_result;
    end


    /* <------------------- State machine -------------------> */
    // A simple 2-state state machine that commands the sqrt
    // SM input: sqrt_done, valid, timer_done
    // SM output: set_go
    typedef enum logic [1:0] { INIT, CALC, WAIT_TMR } state_t;
    state_t state, next_state;

    // Infer the state flop
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n) 
            state <= INIT;
        else 
            state <= next_state;
    end

    // Start the state machine logic
    always_comb begin
        next_state = state;
        set_go = 1'b0;
        timer_clr = 1'b0;
        case (state)
            INIT: begin
                // If new set of data coming in, assert go and wait for the result
                if (valid) begin
                    set_go = 1'b1;
                    next_state = CALC;
                    timer_clr = 1'b1;
                end
            end

            CALC: begin
                // Wait here until the calculation is completed. 
                // If the calculation is completed, go back. and start a new
                // round of calculation if new data is coming in
                if (sqrt_done) begin
                    next_state = WAIT_TMR;
                end
            end

            WAIT_TMR: begin
                if (timer_done) begin
                    timer_clr = 1'b1;
                    next_state = INIT;
                end
            end
        endcase
    end


endmodule