	system u0 (
		.av_dac_external_interface_acknowledge  (<connected-to-av_dac_external_interface_acknowledge>),  //  av_dac_external_interface.acknowledge
		.av_dac_external_interface_irq          (<connected-to-av_dac_external_interface_irq>),          //                           .irq
		.av_dac_external_interface_address      (<connected-to-av_dac_external_interface_address>),      //                           .address
		.av_dac_external_interface_bus_enable   (<connected-to-av_dac_external_interface_bus_enable>),   //                           .bus_enable
		.av_dac_external_interface_byte_enable  (<connected-to-av_dac_external_interface_byte_enable>),  //                           .byte_enable
		.av_dac_external_interface_rw           (<connected-to-av_dac_external_interface_rw>),           //                           .rw
		.av_dac_external_interface_write_data   (<connected-to-av_dac_external_interface_write_data>),   //                           .write_data
		.av_dac_external_interface_read_data    (<connected-to-av_dac_external_interface_read_data>),    //                           .read_data
		.av_uart_external_interface_acknowledge (<connected-to-av_uart_external_interface_acknowledge>), // av_uart_external_interface.acknowledge
		.av_uart_external_interface_irq         (<connected-to-av_uart_external_interface_irq>),         //                           .irq
		.av_uart_external_interface_address     (<connected-to-av_uart_external_interface_address>),     //                           .address
		.av_uart_external_interface_bus_enable  (<connected-to-av_uart_external_interface_bus_enable>),  //                           .bus_enable
		.av_uart_external_interface_byte_enable (<connected-to-av_uart_external_interface_byte_enable>), //                           .byte_enable
		.av_uart_external_interface_rw          (<connected-to-av_uart_external_interface_rw>),          //                           .rw
		.av_uart_external_interface_write_data  (<connected-to-av_uart_external_interface_write_data>),  //                           .write_data
		.av_uart_external_interface_read_data   (<connected-to-av_uart_external_interface_read_data>),   //                           .read_data
		.clk_clk                                (<connected-to-clk_clk>),                                //                        clk.clk
		.clk_sdram_clk                          (<connected-to-clk_sdram_clk>),                          //                  clk_sdram.clk
		.disp0_export                           (<connected-to-disp0_export>),                           //                      disp0.export
		.disp1_export                           (<connected-to-disp1_export>),                           //                      disp1.export
		.disp2_export                           (<connected-to-disp2_export>),                           //                      disp2.export
		.disp3_export                           (<connected-to-disp3_export>),                           //                      disp3.export
		.disp4_export                           (<connected-to-disp4_export>),                           //                      disp4.export
		.disp5_export                           (<connected-to-disp5_export>),                           //                      disp5.export
		.leds_export                            (<connected-to-leds_export>),                            //                       leds.export
		.rst_reset_n                            (<connected-to-rst_reset_n>),                            //                        rst.reset_n
		.sdram_addr                             (<connected-to-sdram_addr>),                             //                      sdram.addr
		.sdram_ba                               (<connected-to-sdram_ba>),                               //                           .ba
		.sdram_cas_n                            (<connected-to-sdram_cas_n>),                            //                           .cas_n
		.sdram_cke                              (<connected-to-sdram_cke>),                              //                           .cke
		.sdram_cs_n                             (<connected-to-sdram_cs_n>),                             //                           .cs_n
		.sdram_dq                               (<connected-to-sdram_dq>),                               //                           .dq
		.sdram_dqm                              (<connected-to-sdram_dqm>),                              //                           .dqm
		.sdram_ras_n                            (<connected-to-sdram_ras_n>),                            //                           .ras_n
		.sdram_we_n                             (<connected-to-sdram_we_n>),                             //                           .we_n
		.sys_clk                                (<connected-to-sys_clk>)                                 //                        sys.clk
	);
