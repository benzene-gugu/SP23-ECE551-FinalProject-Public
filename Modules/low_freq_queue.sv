/*
 * low_freq_queue.sv
 *
 * Author: Yucheng Zang
 * Create: Apr 14, 23 (HW 5)
 *
 * Revision 1: Apr 19, 23   (HW 5, resolved metastable outputs during the 'Full'
 *                           State)
 * Revision 2: Apr 19, 23   (HW 5, resolved a problem which causes rd_ptr to 
 *                           delay one readout round)
 *
 * A circular buffer to store left and right audio lower frequency signals. The 
 * content of this queue will then feed into the low pass (LP) and band 1 (B1) 
 * filters
 *
 * Required modules:
 *  - rise_edge_detector.sv             (Rising Edge Detector for wrt_smpl)
 *  - prescalar_2_to_1.sv               (2-to-1 Prescaler used for wrt_smpl)
 *  - dualPort1024x16.v                 (1024 * 16 dual port memory)
 *
 * It works as follows:
 * 1) In the beginning, before the queues are full (full means it has collected 
 *    1021 samples), it will collect a pair of samples each time signal 'wrt_smpl'
 *    is asserted.
 *    - At this time, the 'old' pointer stays at its position, but the 'new' 
 *      pointer will increment every time a new data is written into the queue
 *    - It does not write out anything, so the 'sequencing' signal will not be 
 *      asserted and remain low
 * 2) After it is full, it will collect a new sample every time 'wrt_smpl' is 
 *    asserted, and write out the 1021 previous samples
 *    - Every time 'wrt_smpl' is asserted, a new pair of data is put into the 
 *      circular queue, and both the 'old' and 'new' pointer will increment at 
 *      the same time.
 *    - It will pull the 'sequencing' signal high and continuously read out the
 *      1021 pairs of data (from 'old' to 'old + 1020')
 *    - After all the 1021 pairs of data has been read out, the 'sequencing' 
 *      signal will be low again
 */
module low_freq_queue (
    input clk,                  // Clock
    input rst_n,                // Async active low reset
    input [15:0] lft_smpl,      // 16-bit newest sample of left audio channel 
                                // from I2S_Serf to be written to the queue
    input [15:0] rght_smpl,     // 16-bit newest sample of right audio channel 
                                // from I2S_Serf to be written to the queue
    input wrt_smpl,             // If high, then we write a new sample into the 
                                // queue every other rising edge. If the queue 
                                // is full, then it will be followed by a readout
                                // from the oldest sample to the (oldest + 1020)
                                // sample. (1021 samples in total)
    output [15:0] lft_out,      // 16-bit samples of the left audio channel to 
                                // be readout from this queue.
    output [15:0] rght_out,     // 16-bit samples of the right audio channel to 
                                // be readout from this queue.   
    output logic sequencing,     // This signal is high the whole time the 1021 
                                // samples are bding readout from the queue 
    output logic queue_full       // A flop that indicates if the queue is full.  Change made by Tianqi Shen
                                // When the queue is full (collected 1021 samples),    
);



    /* <-------------------- Internal Logics --------------------> */
    logic wrt_smpl_pres;        // Prescaled version of 'wrt_smpl'

    logic wrt_smpl_rise;        // Asserted by a rising edge detector when input
                                // signal 'wrt_smpl' has an rising edge

   // logic queue_full;           // A flop that indicates if the queue is full. 
                                // When the queue is full (collected 1021 samples),
                                // this signal will be set to HIGH, and commands
                                // a state transition of the state machine. 
                                // Otherwise, it will be LOW. Check the state 
                                // machine for more detail about state transition

    logic [9:0] new_ptr;        // New pointer, a flop which points where the 
                                // new data comming in this circular queue will 
                                // be stored

    logic [9:0] old_ptr;        // Old pointer, a flop which points the "oldest"
                                // sample hat stored in this queue

    logic [9:0] rd_ptr;         // Read pointer, a flop which is only used during
                                // a readout. It will traverse from the oldest 
                                // sample to the (oldest + 1020) sample

    logic [9:0] rd_ptr_trgt;    // Read pointer target, a flop which stores the
                                // final location where 'rd_ptr' neads to go.
                                // Basically, it stores the value 
                                // [(old_ptr + 1020) % 1024]. When (rd_ptr == 
                                // rd_ptr_trgt), it will command a state transion
                                // of the state machine.  Check the state machine
                                // for more detail about state transition

    logic inc_new_ptr;          // Asserted by the state machine to increment
                                // the value of new_ptr. Check the state machine
                                // for more detail

    logic inc_old_ptr;          // Asserted by the state machine to increment
                                // the value of old_ptr. Check the state machine
                                // for more detail

    logic inc_rd_ptr;           // Asserted by the state machine to increment
                                // the value of rd_ptr. Check the state machine
                                // for more detail

    logic sync_rd_ptr;          // Asserted by the state machine to synchronize
                                // the value of 'rd_ptr' with 'old_ptr'

    logic set_we;               // Set write engable. Connects to port 'we' of 
                                // the module 'dualPort1024x16'. Asserted by the
                                // State machine in order to write new data to 
                                // the dual port memory



    /* <--------------- Instantiate A 2-to-1 Prescalar ---------------> */
    // Connect the input signal 'wrt_smpl' to a 2-to-1 prescalar, so that this 
    // module only write in data every other wrt_smpl
    prescalar_2_to_1 iPrescalar (
                                 .clk(clk),
                                 .rst_n(rst_n),
                                 .raw_signal(wrt_smpl),
                                 .prescaled_signal(wrt_smpl_pres)
                                );



    /* <--------------- Instantiate A Rising Edge Detector ---------------> */
    // This rising edge detector monitors the rise edge of input signal 
    // 'wrt_smpl_pres'
    rise_edge_detector iPres_Rise (     
                                .clk(clk),
                                .rst_n(rst_n),
                                .signal(wrt_smpl_pres),            
                                .rise_edge(wrt_smpl_rise)
                                );


    /* <----------- Instantiate The Two Dual Port Memories -----------> */
    dualPort1024x16 left_Ram (
                              .clk(clk),
                              .we(set_we),
                              .waddr(new_ptr),
                              .raddr(rd_ptr),
                              .wdata(lft_smpl),
                              .rdata(lft_out)
                            );

    dualPort1024x16 Right_Ram (
                              .clk(clk),
                              .we(set_we),
                              .waddr(new_ptr),
                              .raddr(rd_ptr),
                              .wdata(rght_smpl),
                              .rdata(rght_out)
                            );


    /* <-------------- Imply the 'queue_full' flop --------------> */
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            // By default, on reset, 'queue_full' remains LOW indicating that
            // the circular queue is not yet full
            queue_full <= 1'b0;     
        end else if (new_ptr == 10'h3FD) begin      // MOD. 10'h3FC
            // When 'new_ptr' reaches 1021 (0x3FD), it means the queue has 
            // collected 1021 samples, which means it is now full
            queue_full <= 1'b1;
        end

        // Otherwise, it will keep its value of 0 or 1
    end



    /* <-------------- Imply the 'new_ptr' flop --------------> */
    // Increment by one when signal 'inc_new_ptr' is asserted by the state 
    // machine. The (new_ptr % 1024) part is done by the nature of the 10-bit 
    // registor when wrapping around
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n) 
            new_ptr <= 10'h000;
        else if (inc_new_ptr)		// MOD. else if (wrt_smpl_rise) 
            new_ptr <= new_ptr + 1;
    end



    /* <-------------- Imply the 'old_ptr' flop --------------> */
    // Increment by one when signal 'inc_old_ptr' is asserted by the state 
    // machine. The (old_ptr % 1024) part is done by the nature of the 10-bit 
    // registor when wrapping around
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n) 
            old_ptr <= 10'h000;
        else if (inc_old_ptr)
            old_ptr <= old_ptr + 1;
    end



    /* <-------------- Imply the 'rd_ptr' flop --------------> */
    // Increment by one when signal 'inc_rd_ptr' is asserted by the state 
    // machine. The (old_ptr % 1024) part is done by the nature of the 10-bit 
    // registor when wrapping around
    // Also, synchronize the value of 'rd_ptr' with the value of 'old_ptr' when
    // signal 'sync_rd_ptr' is asserted by the state machine
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n) 
            rd_ptr <= 10'h000;
        else begin
            if (sync_rd_ptr)
                rd_ptr <= old_ptr;  // MOD. =   

            if (inc_rd_ptr)
                rd_ptr <= rd_ptr + 1;   // MOD. =
        end
    end



    /* <-------------- Imply the 'rd_ptr_trgt' flop --------------> */
    // If not reset, rd_ptr_trgt's value always equals to (old_ptr + 1020)
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n) 
            rd_ptr_trgt <= 10'h000;
        else 
            rd_ptr_trgt <= old_ptr + 10'h3FC;

    end



    /* <---------------------- State Machine ----------------------> */
    // SM Inputs:
    //  wrt_smpl_rise, queue_full
    // SM Outputs:
    //  set_we, sequencing
    //  inc_new_ptr, inc_old_ptr, inc_rd_ptr, sync_rd_ptr
    // SM States:
    //  NOT_FULL: when the queue is not full, only increment the 'new_ptr' when 
    //            new data coming in
    //  READ_OUT: Readout the data stored in the circular queue. From (old_ptr)
    //            to (old_ptr + 1020)
    //  FULL    : When the queue is full, both 'new_ptr' and 'old_ptr' gets to 
    //            increment when new data coming in
    //  SYNC_RD : A state dedicate to sychnorize rd_ptr with old_ptr, because 
    //            the SRAM needs an extra one clock cycle to store the new data
    //            in 

    typedef enum logic[1:0] { NOT_FULL, FULL, READ_OUT, SYNC_RD } state_t;
    state_t state, next_state;

    // Imply the state flop
    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n)
            state <= NOT_FULL;
        else 
            state <= next_state;
    end


    // State machien combination logic
    always_comb begin
        // Default outputs
        next_state = state;

        set_we = 1'b0;
        sequencing = 1'b0;

        inc_new_ptr = 1'b0;
        inc_old_ptr = 1'b0;
        inc_rd_ptr = 1'b0;
        sync_rd_ptr = 1'b0;

        case (state)
            NOT_FULL : begin
                // When a rising edge of 'wrt_smpl_pres' is detected and the 
                // queue is not yet full, continuing putting new datas in
                if (wrt_smpl_rise) begin
                    set_we = 1'b1;
                    inc_new_ptr = 1'b1;
                end

                // ? Use h3FC and then read
                // When a rising edge is detected and the queue is already full,
                // read one more data in, and start the readout process, which 
                // means that sync the read pointer, pull 'sequencing' to HIGH,
                // and transition to the READ_OUT state
                if (queue_full) begin
                    sync_rd_ptr = 1'b1;
                    sequencing = 1'b1;
                    next_state = READ_OUT;
                end
            end

            READ_OUT : begin
                // If it has not readout 1021 pairs of data (i.e. rd_ptr != 
                // old_ptr + 1020), continue the readout process by pulling 
                // 'sequencing' to HIGH and and increment the 'rd_ptr'
                sequencing = 1'b1;
                if (rd_ptr != rd_ptr_trgt) begin
                    inc_rd_ptr = 1'b1;
                end else begin
                    // Otherwise, leave the state
                    next_state = FULL;
                end
            end

            FULL : begin
                // When new data comes in, store the new data, and discards the 
                // oldest data, then perform a readout process
                if (wrt_smpl_rise) begin
                    set_we = 1'b1;
                    inc_new_ptr = 1'b1;
                    inc_old_ptr = 1'b1;

                    next_state = SYNC_RD;
                end
            end

            SYNC_RD : begin   
                sync_rd_ptr = 1'b1;  
                next_state = READ_OUT;
            end

        endcase

    end

endmodule
