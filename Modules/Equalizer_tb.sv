module Equalizer_tb();

	logic clk,RST_n;
	logic next_n,prev_n,Flt_n;
	logic [11:0] LP,B1,B2,B3,HP,VOL;

	logic [7:0] LED;
	logic ADC_SS_n,ADC_MOSI,ADC_MISO,ADC_SCLK;
	logic mic_clk;	// ????? where have we use this signal
	logic I2S_data,I2S_ws,I2S_sclk;
	logic cmd_n,RX_TX,TX_RX;
	logic lft_PDM,rght_PDM;
	logic lft_PDM_n, rght_PDM_n;
	
	logic sht_dwn;

	// logics for wave analyze
	logic [31:0] period_lft, period_rght, amplitude_lft, amplitude_rght;
	logic vld_lft, vld_rght;
	
	//////////////////////
	// Instantiate DUT //
	////////////////////
	Equalizer iDUT(.clk(clk),.RST_n(RST_n),.LED(LED),
		.ADC_SS_n(ADC_SS_n),.ADC_MOSI(ADC_MOSI),.ADC_SCLK(ADC_SCLK),.ADC_MISO(ADC_MISO),
        .I2S_data(I2S_data),.I2S_ws(I2S_ws),.I2S_sclk(I2S_sclk),.cmd_n(cmd_n),
		.sht_dwn(sht_dwn),.lft_PDM(lft_PDM),.rght_PDM(rght_PDM), .lft_PDM_n(lft_PDM_n), .rght_PDM_n(rght_PDM_n), .Flt_n(Flt_n),
		.next_n(next_n),.prev_n(prev_n),.RX(RX_TX),.TX(TX_RX));
	
	
	//////////////////////////////////////////
	// Instantiate model of RN52 BT Module //
	////////////////////////////////////////	
	RN52 iRN52(.clk(clk),.RST_n(RST_n),.cmd_n(cmd_n),.RX(TX_RX),.TX(RX_TX),.I2S_sclk(I2S_sclk),
		.I2S_data(I2S_data),.I2S_ws(I2S_ws));

	//////////////////////////////////////////////
	// Instantiate model of A2D and Slide Pots //
	////////////////////////////////////////////		   
	A2D_with_Pots iPOTs(.clk(clk),.rst_n(RST_n),.SS_n(ADC_SS_n),.SCLK(ADC_SCLK),.MISO(ADC_MISO),
		.MOSI(ADC_MOSI),.LP(LP),.B1(B1),.B2(B2),.B3(B3),.HP(HP),.VOL(VOL));

	// instantiate model for testing frequency and amplitude
	wave_analyze iLEFT (.clk(clk), .rst_n(RST_n), .wave(iDUT.iDRV.lft_reg), .period(period_lft), .amplitude(amplitude_lft), .vld(vld_lft));
	wave_analyze iRGHT (.clk(clk), .rst_n(RST_n), .wave(iDUT.iDRV.rght_reg), .period(period_rght), .amplitude(amplitude_rght), .vld(vld_rght));
	
	
	initial begin
		// Initialize signals
        clk = 0;
        RST_n = 0;
       
        Flt_n = 1;
        next_n = 1;
        prev_n = 1;
        LP = 12'd2048;
        B1 = 0;
        B2 = 0;
        B3 = 0;
        HP = 0;
        VOL = 12'd1024;

        // Apply reset
		@(posedge clk);
        @(negedge clk);
        RST_n = 1;

        // Test fault detection
        // Set Flt_n signal here
		// repeat (40) @(posedge clk);
        // Flt_n = 0;
		// repeat (10) @(posedge clk);
        // Flt_n = 1;

        // Run the test for some time
		repeat (4000000) @(posedge clk);
		
		Flt_n = 1;
        next_n = 1;
        prev_n = 1;
        LP = 0;
        B1 = 12'd2048;
        B2 = 0;
        B3 = 0;
        HP = 0;
        VOL = 12'd1024;
		
		// Run the test for some time
		repeat (150000) @(posedge clk);
		
		Flt_n = 1;
        next_n = 1;
        prev_n = 1;
        LP = 0;
        B1 = 0;
        B2 = 12'd2048;
        B3 = 0;
        HP = 0;
        VOL = 12'd1024;
		
		// Run the test for some time
		repeat (150000) @(posedge clk);
		
		Flt_n = 1;
        next_n = 1;
        prev_n = 1;
        LP = 0;
        B1 = 0;
        B2 = 0;
        B3 = 12'd2048;
        HP = 0;
        VOL = 12'd1024;
		
		// Run the test for some time
		repeat (150000) @(posedge clk);
		
		Flt_n = 1;
        next_n = 1;
        prev_n = 1;
        LP = 0;
        B1 = 0;
        B2 = 0;
        B3 = 0;
        HP = 12'd2048;
        VOL = 12'd1024;
		
		// Run the test for some time
		repeat (150000) @(posedge clk);
		
		
        // Finish simulation
        $stop();
  
end

always
  #5 clk = ~ clk;
  
endmodule	  