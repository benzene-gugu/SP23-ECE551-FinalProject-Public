/*
 * sqrt.sv
 *
 * Implement a square root function of an unsigned 16-bit number ([15:0] mag). 
 * 
 * This module calculates the square root of the input 'mag' using 8 successive 
 * multiplies. Calculation starts when signal 'go' is asserted, and when 
 * calculation is complete this module will assert signal 'done'
 * 
 * NOTE: Piror to the assertion of signal 'done', 'sqrt' may contain garbage 
 * information
 */
module sqrt (
    input [15:0] mag,       // A 16-bit unsigned number which to calculate the 
                            // square root of
    input go,               // Assert this signal to initate a new calculate
    input clk,              // Clock
    input rst_n,            // Active-low reset
    output reg [7:0] sqrt,  // The result of the calucation
    output done             // Assert when calculation is completed
);

    // Internal signals
    logic [7:0] calc_iteration_counter;     // 1-hot 8-bit register that indicates 
                                            // the iteration of calculations

    logic [7:0] next_calc_iteration;        // The next value goes into 
                                            // calc_iteration_counter

    logic [7:0] next_sqrt_value;            // The next value goes into 
                                            // next_sqrt_value
    

    /* <--------------- Calculation Iteration Counter ---------------> */
    // When reseted, the counter receives value 8'b1000_0000, because the
    // comparasion starts with the MSB of the sqrt. 
    // See the part for the successive multiplier for more detail
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n) 
            calc_iteration_counter <= 8'b1000_0000;
        else 
            calc_iteration_counter <= next_calc_iteration;
    end

    // calc_iteration_counter counts from 1000_0000, 0100_0000, 0010_0000 ...
    // until 0000_0000. When it contains all 0s, it means all 8 calculations
    // are finished, so assert signal 'done' 
    assign done = ~(|calc_iteration_counter);


    /* <--------------- sqrt (The Flop Stores Result) ---------------> */
    // Infer the flop that stores the result (sqrt)
    // The successive calculation starts with the MSB set
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n)
            sqrt <= 8'b1000_0000;
        else 
            sqrt <= next_sqrt_value;
    end


    /* <--------------- State Machine ---------------> */
    // State machine input: rst_n, go, done
    // State machien output: next_state, next_calc_iteration, next_sqrt_value
    typedef enum reg [1:0] { IDLE, CALC, DONE } state_t;
    state_t state, next_state;

    // Infer the state flop
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n) 
            state <= IDLE;
        else 
            state <= next_state;
    end

    // Start the state machine logic
    always_comb begin
        // Default output values
        next_state = state;                     
        next_calc_iteration = calc_iteration_counter; 
        next_sqrt_value = sqrt;                        

        case (state)
            IDLE : begin
                if (go) 
                    next_state = CALC;
            end
            
            CALC : begin
                // If sqrt^2 is greater than the number we are takign the square 
                // root of, we clear the current bit and set the next bit; else, 
                // we keep the current bit and then set the next bit
                if ((sqrt * sqrt) > mag) begin
                    // If so, clear the current bit
                    next_sqrt_value = sqrt &~ calc_iteration_counter;
                end else begin
                    // If not, keep the current bit
                    next_sqrt_value = sqrt;
                end

                // Decrement the counter, shift right by 1
                next_calc_iteration = {1'b0, calc_iteration_counter[7:1]};

                // Set the next bit in the next_sqrt_value
                next_sqrt_value = next_sqrt_value | next_calc_iteration;

                if (done)   // if all the bits in calc_iteration_counter are 0
                    next_state = DONE;
            end

            DONE : ;    // Do nothing, stay here until reseted

            default: next_state = IDLE;
        endcase
        
    end

endmodule