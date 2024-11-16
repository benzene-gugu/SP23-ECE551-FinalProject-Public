module wave_analyze (VALID, rst_n, wave, period, amplitude, vld);
	
	parameter VOL = 1024;
	
    input logic VALID;
	input logic rst_n;
	input [15:0] wave;
	output logic [31:0] period;
	output logic [31:0] amplitude;
	output logic vld;
	
	logic [15:0] prev_sig, curr_sig, next_sig;
	logic [15:0] max_peak, min_peak;
	
	// define max peak time, min peak time
	logic [31:0] max_time;
	logic [31:0] min_time;
	
	// define the signal represent when the max peak and min peak is valid
	logic max_vld;
	logic min_vld;
	
	// update prev, curr, next
	always_ff  @(posedge VALID, negedge rst_n) begin
		if (!rst_n) begin
			prev_sig <= wave;
			curr_sig <= wave;
			next_sig <= wave;
		end
		else begin
			prev_sig <= curr_sig;
			curr_sig <= next_sig;
			next_sig <= wave; 
		end
	end
	
		// update max_peak
	always_ff  @(posedge VALID, negedge rst_n) begin
		if (!rst_n) begin
			max_peak <= wave;
		end
		else if (curr_sig > max_peak) begin
			max_peak <= curr_sig;
		end
	end
	
	// update min_peak
	always_ff  @(posedge VALID, negedge rst_n) begin
		if (!rst_n) begin
			min_peak <= wave;
		end
		else if (curr_sig < min_peak) begin
			min_peak <= curr_sig;
		end
	end

	// update max_vld
	always_ff @(posedge VALID, negedge rst_n) begin
		if (!rst_n) begin
			max_vld <= 0;
		end
		else if (!max_vld && max_peak ) 
			max_vld <= 1;
	end
	
	// update min_vld
	always_ff @(posedge VALID, negedge rst_n) begin
		if (!rst_n) begin
			min_vld <= 0;
		end
		else if (!min_vld && curr_sig < next_sig)
			min_vld <= 1;
	end
	
	// record max_time and min_time
	always_ff @(posedge VALID, negedge rst_n)
		if (!rst_n) begin
			max_time <= 'x;
		end
		else if (!max_vld)
				max_time <= $time;
		
		// record max_time and min_time
	always_ff @(posedge VALID, negedge rst_n)
		if (!rst_n) begin
			min_time <= 'x;
		end
		else if (!min_vld)
				min_time <= $time;

	// output amplitude and peroid based on 
	always_ff @(posedge VALID, negedge rst_n)
		if (!rst_n) begin
			amplitude <= 0;
			period <= 0;
		end
		else if (vld) begin
			amplitude <= max_peak - min_peak;
			period <= (max_time > min_time) ? (max_time - min_time)*2 : (min_time - max_time)*2;
		end
		
	assign vld = max_vld && min_vld;
endmodule