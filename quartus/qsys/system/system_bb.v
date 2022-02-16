
module system (
	av_dac_external_interface_acknowledge,
	av_dac_external_interface_irq,
	av_dac_external_interface_address,
	av_dac_external_interface_bus_enable,
	av_dac_external_interface_byte_enable,
	av_dac_external_interface_rw,
	av_dac_external_interface_write_data,
	av_dac_external_interface_read_data,
	av_hpc_external_interface_acknowledge,
	av_hpc_external_interface_irq,
	av_hpc_external_interface_address,
	av_hpc_external_interface_bus_enable,
	av_hpc_external_interface_byte_enable,
	av_hpc_external_interface_rw,
	av_hpc_external_interface_write_data,
	av_hpc_external_interface_read_data,
	av_uart_external_interface_acknowledge,
	av_uart_external_interface_irq,
	av_uart_external_interface_address,
	av_uart_external_interface_bus_enable,
	av_uart_external_interface_byte_enable,
	av_uart_external_interface_rw,
	av_uart_external_interface_write_data,
	av_uart_external_interface_read_data,
	av_vga_external_interface_acknowledge,
	av_vga_external_interface_irq,
	av_vga_external_interface_address,
	av_vga_external_interface_bus_enable,
	av_vga_external_interface_byte_enable,
	av_vga_external_interface_rw,
	av_vga_external_interface_write_data,
	av_vga_external_interface_read_data,
	clk_clk,
	clk_sdram_clk,
	disp0_export,
	disp1_export,
	disp2_export,
	disp3_export,
	disp4_export,
	disp5_export,
	leds_export,
	riscv_mk1_debug_vector_0,
	rst_reset_n,
	sdram_addr,
	sdram_ba,
	sdram_cas_n,
	sdram_cke,
	sdram_cs_n,
	sdram_dq,
	sdram_dqm,
	sdram_ras_n,
	sdram_we_n,
	sys_clk);	

	input		av_dac_external_interface_acknowledge;
	input		av_dac_external_interface_irq;
	output	[2:0]	av_dac_external_interface_address;
	output		av_dac_external_interface_bus_enable;
	output	[3:0]	av_dac_external_interface_byte_enable;
	output		av_dac_external_interface_rw;
	output	[31:0]	av_dac_external_interface_write_data;
	input	[31:0]	av_dac_external_interface_read_data;
	input		av_hpc_external_interface_acknowledge;
	input		av_hpc_external_interface_irq;
	output	[5:0]	av_hpc_external_interface_address;
	output		av_hpc_external_interface_bus_enable;
	output	[3:0]	av_hpc_external_interface_byte_enable;
	output		av_hpc_external_interface_rw;
	output	[31:0]	av_hpc_external_interface_write_data;
	input	[31:0]	av_hpc_external_interface_read_data;
	input		av_uart_external_interface_acknowledge;
	input		av_uart_external_interface_irq;
	output	[2:0]	av_uart_external_interface_address;
	output		av_uart_external_interface_bus_enable;
	output	[3:0]	av_uart_external_interface_byte_enable;
	output		av_uart_external_interface_rw;
	output	[31:0]	av_uart_external_interface_write_data;
	input	[31:0]	av_uart_external_interface_read_data;
	input		av_vga_external_interface_acknowledge;
	input		av_vga_external_interface_irq;
	output	[3:0]	av_vga_external_interface_address;
	output		av_vga_external_interface_bus_enable;
	output	[3:0]	av_vga_external_interface_byte_enable;
	output		av_vga_external_interface_rw;
	output	[31:0]	av_vga_external_interface_write_data;
	input	[31:0]	av_vga_external_interface_read_data;
	input		clk_clk;
	output		clk_sdram_clk;
	output	[7:0]	disp0_export;
	output	[7:0]	disp1_export;
	output	[7:0]	disp2_export;
	output	[7:0]	disp3_export;
	output	[7:0]	disp4_export;
	output	[7:0]	disp5_export;
	output	[9:0]	leds_export;
	output	[31:0]	riscv_mk1_debug_vector_0;
	input		rst_reset_n;
	output	[12:0]	sdram_addr;
	output	[1:0]	sdram_ba;
	output		sdram_cas_n;
	output		sdram_cke;
	output		sdram_cs_n;
	inout	[15:0]	sdram_dq;
	output	[1:0]	sdram_dqm;
	output		sdram_ras_n;
	output		sdram_we_n;
	output		sys_clk;
endmodule
