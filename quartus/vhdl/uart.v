/*
	File: 	UART.v
	Date:	11/12/2019
*/

module UART #(
	//parameters
	parameter 	CLOCK_FREQUENCY,
	parameter 	BAUD_RATE,
	parameter 	TX_FIFO_DEPTH = 32,	//TX FIFO depth in bytes (max 256)
	parameter 	RX_FIFO_DEPTH = 32	//RX FIFO depth in bytes (max 256)
	)(
	//Clock and Reset
	input  wire				  i_clock,
	input  wire				  i_reset_n,
	
	output wire [7:0]   o_tx_fifo_q,
	output wire				  o_tx_fifo_wrreq,
	output wire				  o_tx_fifo_rdreq,
	output wire				  o_tx_fifo_empty,
	output wire				  o_rx_sampling,
	//Avalon slave interface
	input  wire [2:0]	  i_address,
	input  wire				  i_read,
	input  wire				  i_write,
	input  wire [31:0]	i_writedata,
	output reg  [31:0]	o_readdata,
	output reg				  o_acknowledge	= 1'b0,
	//Serial lines
	input  wire				  i_RX,
	output wire 			  o_TX
	);
	
	//TX FIFO
	reg  [7:0]	tx_fifo_data;
	reg  			  tx_fifo_rdreq	= 1'b0;
	wire  		  tx_fifo_sclr;
	reg  			  tx_fifo_wrreq	= 1'b0;
	wire			  tx_fifo_empty;
	wire [7:0]	tx_fifo_q;
	wire [7:0]	tx_fifo_usedw;
	//TX
	reg  			tx_start	= 1'b0;
	reg [7:0]	tx_data;
	wire 			tx_done;
	
	//RX FIFO
	wire			  rx_fifo_sclr;
	reg 			  rx_fifo_rdreq	= 1'b0;
	reg 			  rx_fifo_wrreq	= 1'b0;
	wire 			  rx_fifo_empty;
	wire [7:0]	rx_fifo_q;
	wire [7:0]	rx_fifo_usedw;
	//RX
	wire			  rx_data_ready;
	wire [7:0]	rx_data;
	
	wire [7:0]	tx_fifo_space = TX_FIFO_DEPTH - tx_fifo_usedw;
	
	assign tx_fifo_sclr	= !i_reset_n;
	assign rx_fifo_sclr = !i_reset_n;
	
	
	assign o_tx_fifo_q		  = tx_fifo_q;
	assign o_tx_fifo_wrreq	= tx_fifo_wrreq;
	assign o_tx_fifo_rdreq	= tx_fifo_rdreq;
	assign o_tx_fifo_empty	= tx_fifo_empty;
	
	//UART state machine
	localparam S_UART_IDLE = 0, S_UART_WRITE = 1, S_UART_READ = 2;
	reg [1:0] uart_state = S_UART_IDLE;
	
	always @(posedge i_clock) begin
	
		case (uart_state)
			S_UART_IDLE: begin
				if(i_write) begin
					if(i_address == 3'h0) begin	//Write to tx fifo
						tx_fifo_data	<= i_writedata[7:0];
						tx_fifo_wrreq	<= 1'b1;
						o_acknowledge	<= 1'b1;
					end
					uart_state	<= S_UART_WRITE;
				end
				if(i_read) begin
					case (i_address)
						3'h0: begin
							if(!rx_fifo_empty) begin
								rx_fifo_rdreq	<= 1'b1;
								o_readdata 		<= {8'h00, rx_fifo_usedw, !rx_fifo_empty, 7'h00, rx_fifo_q};
							end
							else
								o_readdata		<= 32'h0000_0000;
						end
						3'h4: begin
							o_readdata <= {8'h00, tx_fifo_space, 16'h0000};
						end
						default: begin
							o_readdata <= 32'h0000_0000;
						end
					endcase
					o_acknowledge	<= 1'b1;
					uart_state		<= S_UART_READ;
				end
			end
			S_UART_WRITE: begin
				o_acknowledge	<= 1'b0;
				tx_fifo_wrreq	<= 1'b0;
				uart_state 		<= S_UART_IDLE;
			end
			S_UART_READ: begin
				o_acknowledge	<= 1'b0;
				rx_fifo_rdreq	<= 1'b0;
				uart_state 		<= S_UART_IDLE;
			end
		endcase
	end

	//TX state machine
	localparam [0:0] S_TX_IDLE = 0;
	localparam [0:0] S_TX_BUSY = 1;
	reg tx_state = S_TX_IDLE;
	
	always @(posedge i_clock) begin
		case (tx_state)
			S_TX_IDLE: begin
				if(!tx_fifo_empty) begin
					tx_data			<= tx_fifo_q;
					tx_start			<= 1'b1;
					tx_fifo_rdreq	<= 1'b1;
					tx_state			<= S_TX_BUSY;
				end
			end
			S_TX_BUSY: begin
				tx_start			<= 1'b0;
				tx_fifo_rdreq	<= 1'b0;
				if(tx_done)
					tx_state		<= S_TX_IDLE;
			end
		endcase
	end

	wire [$clog2(TX_FIFO_DEPTH)-1:0] _tx_fifo_usedw;
	assign tx_fifo_usedw = 8'h00 | _tx_fifo_usedw;
	
	UART_FIFO #( .WIDTH(8), .DEPTH(TX_FIFO_DEPTH)
		) tx_fifo (
		.clock	(i_clock),
		.data		(tx_fifo_data),
		.rdreq	(tx_fifo_rdreq),
		.sclr		(tx_fifo_sclr),
		.wrreq	(tx_fifo_wrreq),
		.empty	(tx_fifo_empty),
		.q			(tx_fifo_q),
		.usedw	(_tx_fifo_usedw)
	);

	UART_TX #( .CLK_PER_BIT(CLOCK_FREQUENCY / BAUD_RATE)
		) uart_tx (
		.i_clock	(i_clock),
		.i_start	(tx_start),
		.i_data	(tx_data),
		.o_done	(tx_done),
		.o_tx		(o_TX)
	);
	
	//RX state machine
	localparam [0:0] S_RX_IDLE = 0;
	localparam [0:0] S_RX_BUSY = 1;
	reg rx_state = S_RX_IDLE;
	
	always @(posedge i_clock) begin
		case (rx_state)
			S_RX_IDLE: begin
				if(rx_data_ready) begin
					rx_fifo_wrreq	<= 1'b1;
					rx_state		<= S_RX_BUSY;
				end
			end
			S_RX_BUSY: begin
				rx_fifo_wrreq	<= 1'b0;
				rx_state		<= S_RX_IDLE;
			end
		endcase
	end
	
	wire [$clog2(RX_FIFO_DEPTH)-1:0] _rx_fifo_usedw;
	assign rx_fifo_usedw = _rx_fifo_usedw == 0 ? 8'h00 : (8'h00 | _rx_fifo_usedw) - 1;
	
	UART_FIFO #( .WIDTH(8), .DEPTH(RX_FIFO_DEPTH)
		) rx_fifo (
		.clock	(i_clock),
		.data		(rx_data),
		.rdreq	(rx_fifo_rdreq),
		.sclr		(rx_fifo_sclr),
		.wrreq	(rx_fifo_wrreq),
		.empty	(rx_fifo_empty),
		.q			(rx_fifo_q),
		.usedw	(_rx_fifo_usedw)
	);
	

	UART_RX #( .CLK_PER_BIT(CLOCK_FREQUENCY / BAUD_RATE)
		) uart_rx (
		.i_clock			(i_clock),
		.i_rx				  (i_RX),
		.o_data_ready	(rx_data_ready),
		.o_data			  (rx_data),
		.o_sampling		(o_rx_sampling)
	);

endmodule


/*  
	module:	UART_TX
	
	Whaits for the i_transmit to be asserted, than starts trasmitting i_data out the o_tx line
*/
module UART_TX(
	input wire			i_clock,	//Clock for the module, at least 2x Baud Rate
	input wire  		i_start,	//Asserted for une clock cycle, start the transmitter
	input wire [7:0]	i_data,		//Data to be transmitted
	output reg 			o_done,		//Asserted for one clock cycle, signals the end of transmission
	output reg			o_tx		//Transmit line
	);
	
	//Parameters
	parameter CLK_PER_BIT;	//Number of clocks for each bit (Clock Frequency / Baud Rate)
	
	//Registers
	reg [19:0]	counter;
	reg [2:0]	bit_index;
	reg [7:0]	data;
	
	//State Machine
	localparam S_IDLE = 0, S_START_BIT = 1, S_DATA_BITS = 2, S_STOP_BIT = 3;
	reg [1:0] state = S_IDLE;
	
	always @(posedge i_clock) begin
		case (state)
			S_IDLE: begin
				o_tx		<= 1'b1;
				counter		<= 20'd0;
				bit_index	<= 3'd0;
				o_done		<= 1'b0;
				
				if(i_start) begin
					data	<= i_data;
					state	<= S_START_BIT;
				end
			end
			S_START_BIT: begin
				o_tx	<= 1'b0;
				counter	<= counter + 20'd1;
				
				if(counter >= CLK_PER_BIT) begin
					counter	<= 20'd0;
					state	<= S_DATA_BITS;
				end
			end
			S_DATA_BITS: begin
				o_tx	<= data[bit_index];
				counter <= counter + 20'd1;
				
				if(counter >= CLK_PER_BIT) begin
					counter		<= 20'd0;
					bit_index	<= bit_index + 3'd1;
					if(bit_index == 3'd7)
						state <= S_STOP_BIT;
				end
			end
			S_STOP_BIT: begin
				o_tx	<= 1'b1;
				counter	<= counter + 20'd1;
				if(counter >= CLK_PER_BIT) begin
					o_done	<= 1'b1;
					state	<= S_IDLE;
				end
			end
		endcase
	end
	
endmodule


/*  
	module:	UART_RX
	
	Whaits for the i_transmit to be asserted, than starts trasmitting i_data out the o_tx line
*/
module UART_RX(
	input  wire			  i_clock,		  //Clock for the module, at least 2x Baud Rate
	input  wire  		  i_rx,			    //RX line
	output reg			  o_data_ready,	//Asserted for one clock cycle, signals that a new data byte is bee received
	output reg [7:0]	o_data,			  //Data received
	output reg 			  o_sampling
	);

	//Parameters
	parameter CLK_PER_BIT;	//Number of clocks for each bit (Clock Frequency / Baud Rate)
	
	//Registers
	reg [19:0]	counter;
	reg [2:0]	bit_index;
	reg [7:0]	data;
	
	//Double flop the input data to prevent metastability
	reg _rx;
	reg rx;
	always @(posedge i_clock) begin
		_rx <= i_rx;
		rx	<= _rx;
	end
	
	//State Machine
	localparam S_IDLE = 0, S_START_BIT = 1, S_DATA_BITS = 2, S_STOP_BIT = 3;
	reg [1:0] state = S_IDLE;

	always @(posedge i_clock) begin
		case (state)
			S_IDLE: begin
				counter			  <= 20'd0;
				bit_index	  	<= 3'd0;
				o_data_ready	<= 1'b0;
				o_sampling		<= 1'b0;
				if(!rx)
					state	<= S_START_BIT;
			end
			S_START_BIT: begin
				counter <= counter + 20'd1;
				if(counter >= (CLK_PER_BIT >> 1) - 3) begin
					if(!rx) begin
						counter	<= 20'd0;
						
						o_sampling	<= !o_sampling;
						
						state		<= S_DATA_BITS;
					end
					else
						state	<= S_IDLE;
				end
			end
			S_DATA_BITS: begin
				counter	<= counter + 20'd1;
				if(counter >= (CLK_PER_BIT - 1)) begin
					counter				  <= 20'd0;
					bit_index			  <= bit_index + 3'd1;
					data[bit_index]	<= rx;
					
					o_sampling			<= !o_sampling;
					
					if(bit_index == 3'd7)
						state	<= S_STOP_BIT;
				end
			end
			S_STOP_BIT: begin
				counter	<= counter + 20'd1;
				if(counter >= CLK_PER_BIT) begin
					o_data			  <= data;
					o_data_ready	<= 1'b1;
					state				  <= S_IDLE;
				end
			end
		endcase
	end
	
endmodule


module UART_FIFO  #(
	parameter 	WIDTH = 8,			//Data width
	parameter 	DEPTH = 32			//FIFO depth in words
	)(
	input wire 								clock,	//Clock for the module
	input wire [WIDTH-1:0]				data,		//Input data
	input wire 								rdreq,	//Read request
	input wire								sclr,		//Syncronus clear
	input wire								wrreq,	//Write request
	output wire								empty,	//FIFO empty flag
	output wire [WIDTH-1:0]				q,			//Output data
	output wire [$clog2(DEPTH)-1:0]	usedw		//FIFO used words
	);
	
	reg [$clog2(DEPTH)-1:0]	r_read_ptr	= 1;
	reg [$clog2(DEPTH)-1:0]	r_write_ptr	= 0;
	reg [WIDTH-1:0]			r_q;
	reg [$clog2(DEPTH)-1:0] r_usedw = 0;
	reg 							r_empty = 1;
	
	assign usedw	= r_usedw;
	assign q 		= r_q;
	assign empty	= r_empty;

	wire [WIDTH-1:0] 	r_ram_q;
	wire					r_ram_we;
	
	assign r_ram_we = (wrreq && usedw < DEPTH-1);
	
	simple_dual_port_ram_single_clock #(
		.DATA_WIDTH	(WIDTH),
		.ADDR_WIDTH	($clog2(DEPTH))
		) fifo_ram (
		.clk			(clock),
		.we			(r_ram_we),
		.data			(data),
		.read_addr	(r_read_ptr),
		.write_addr	(r_write_ptr),
		.q				(r_ram_q)
	);
	
	always @(posedge clock) begin
		if(sclr) begin
			r_read_ptr	<= 1;
			r_write_ptr	<= 0;
			r_usedw		<= 0;
			r_empty		<= 1;
		end
		else begin	

			if(rdreq && !empty) begin
				r_q 			<= r_ram_q;
				r_read_ptr 	<= r_read_ptr + 1;
				r_usedw		<= r_usedw - 1;
				r_empty		<= (r_usedw - 1) == 0;
			end
			
			if(wrreq && usedw < DEPTH-1) begin
				r_write_ptr 					<= r_write_ptr + 1;
				r_usedw							<= r_usedw + 1;
				r_empty							<= 0;
				
				if(empty)
					r_q <= data;
			end
			
		end
	end
	

endmodule



// Quartus Prime Verilog Template
// Simple Dual Port RAM with separate read/write addresses and
// single read/write clock

module simple_dual_port_ram_single_clock
#(parameter DATA_WIDTH=8, parameter ADDR_WIDTH=6)
(
	input [(DATA_WIDTH-1):0] data,
	input [(ADDR_WIDTH-1):0] read_addr, write_addr,
	input we, clk,
	output reg [(DATA_WIDTH-1):0] q
);

	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

	always @ (posedge clk)
	begin
		// Write
		if (we)
			ram[write_addr] <= data;

		// Read (if read_addr == write_addr, return OLD data).	To return
		// NEW data, use = (blocking write) rather than <= (non-blocking write)
		// in the write assignment.	 NOTE: NEW data may require extra bypass
		// logic around the RAM.
		q <= ram[read_addr];
	end

endmodule