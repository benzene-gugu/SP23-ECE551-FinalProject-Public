module FIR_x #(
    // Parameter to indicate which band is the filter being used for
    parameter BAND = 2
)
(
    // Global Control signals
    input  logic               clk,        // Clock signal
    input  logic               rst_n,      // Asynchronous active low reset signal

    // Input signals from the queue
    input  logic signed [15:0] lft_in,     // Left channel input from the queue
    input  logic signed [15:0] rght_in,    // Right channel input from the queue
    input  logic               sequencing, // Logic output from the queue to indicate that is currently reading the queue

    // Output signals for the FIR filter
    output logic [15:0]        lft_out,    // Left channel output from the FIR filter
    output logic [15:0]        rght_out    // Right channel output from the FIR filter
);

    // Declare internal signals for the address adder
    logic [9:0] addr_adder;     // The address to be accessed from the coefficient ROM
    logic       addr_adder_en;  // Enable signal for the address adder
    logic       addr_adder_clr; // Clear signal for the address adder

    // Instantiate the address adder
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            addr_adder <= '0;
        end
        else begin
            if(addr_adder_clr) begin
                addr_adder <= '0;
            end
            else if(addr_adder_en) begin
                addr_adder <= addr_adder + 1;
            end
        end
    end

    // Declare internal signals for the coefficient ROM
    logic signed [15:0] coefficient; // The coefficient to be used for the FIR filter

    // Instantiate the coefficient ROM
    generate
        case (BAND)
            0: begin
                ROM_LP iROM(
                    .clk,
                    .addr(addr_adder),
                    .dout(coefficient)
                );
            end
            1: begin
                ROM_B1 iROM(
                    .clk,
                    .addr(addr_adder),
                    .dout(coefficient)
                );
            end
            2: begin
                ROM_B2 iROM(
                    .clk,
                    .addr(addr_adder),
                    .dout(coefficient)
                );
            end
            3: begin
                ROM_B3 iROM(
                    .clk,
                    .addr(addr_adder),
                    .dout(coefficient)
                );
            end
            4: begin
                ROM_HP iROM(
                    .clk,
                    .addr(addr_adder),
                    .dout(coefficient)
                );
            end 
        endcase
    endgenerate

    // Declare internal signals for the multiplier
    logic signed [31:0] left_scaled;  // The scaled left channel input
    logic signed [31:0] right_scaled; // The scaled right channel input

    // Instantiate the multiplier
    assign left_scaled = lft_in * coefficient;
    assign right_scaled = rght_in * coefficient;

    // Declare internal signals for the convolution accumulator
    logic signed [31:0] left_acc;   // The accumulator for the left channel
    logic signed [31:0] right_acc;  // The accumulator for the right channel
    logic               acc_en;     // Enable signal for the convolution accumulator
    logic               acc_clr;    // Clear signal for the convolution accumulator

    // Instantiate the convolution accumulator
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            left_acc <= '0;
            right_acc <= '0;
        end
        else begin
            if(acc_clr) begin
                left_acc <= '0;
                right_acc <= '0;
            end
            else if(acc_en) begin
                left_acc <= left_acc + left_scaled;
                right_acc <= right_acc + right_scaled;
            end
        end
    end
    assign lft_out = unsigned' (left_acc[30:15]);
    assign rght_out = unsigned' (right_acc[30:15]);

    // Declare internal signals for the state machine
    typedef enum logic {
        IDLE = 1'b0,
        CONV = 1'b1
    } state_t;
    state_t state;      // The current state of the state machine
    state_t next_state; // The next state of the state machine

    // Instantiate the state machine
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    // Instantiate the next state transition logic
    always_comb begin
        addr_adder_clr = 1'b0;
        addr_adder_en = 1'b0;
        acc_clr = 1'b0;
        acc_en = 1'b0;
        next_state = state;
        case(state)
            IDLE: begin
                if(sequencing) begin
                    acc_clr = 1'b1;
                    addr_adder_en = 1'b1;
                    acc_en = 1'b1;
                    next_state = CONV;
                end
                else begin
                    addr_adder_clr = 1'b1;
                end
            end
            CONV: begin
                if(sequencing) begin
                    addr_adder_en = 1'b1;
                    acc_en = 1'b1;
                end
                else begin
                    addr_adder_clr = 1'b1;
                    next_state = IDLE;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule