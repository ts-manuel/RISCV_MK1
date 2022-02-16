#**************************************************************
# This .sdc file is created by Terasic Tool.
# Users are recommended to modify this file to match users logic.
#**************************************************************

#**************************************************************
# Create Clock
#**************************************************************
create_clock -period "10.0 MHz" [get_ports ADC_CLK_10]
create_clock -period "50.0 MHz" [get_ports MAX10_CLK1_50]
create_clock -period "50.0 MHz" [get_ports MAX10_CLK2_50]

#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************
set_false_path -from [get_ports {KEY[0] KEY[1]}]
set_false_path -to [get_ports HEX*]
set_false_path -to [get_ports LEDR*]
# UART RX / TX
set_false_path -from [get_ports GPIO[0]]
set_false_path -to [get_ports GPIO[1]]
# DAC
set_false_path -to [get_ports {ARDUINO_IO[12] ARDUINO_IO[13]}]
# VGA
set_false_path -to [get_ports {VGA_R* VGA_G* VGA_B* VGA_HS VGA_VS}]


#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************



#**************************************************************
# SDRAM
#**************************************************************
create_generated_clock -name dram_clk_out -source [get_nets {soc|altpll_0|sd1|wire_pll7_clk[1]}] [get_ports {DRAM_CLK}]
set_input_delay -clock { dram_clk_out } -max [expr 1 + 5.4] [get_ports DRAM_DQ*]
set_input_delay -clock { dram_clk_out } -min [expr 1 + 2.7] [get_ports DRAM_DQ*]
set_output_delay -clock { dram_clk_out } -max  1.5 [get_ports {DRAM_CS_N DRAM_CAS_N DRAM_RAS_N DRAM_WE_N DRAM_UDQM DRAM_LDQM DRAM_DQ* DRAM_ADDR* DRAM_BA*}]
set_output_delay -clock { dram_clk_out } -min -0.8 [get_ports {DRAM_CS_N DRAM_CAS_N DRAM_RAS_N DRAM_WE_N DRAM_UDQM DRAM_LDQM DRAM_DQ* DRAM_ADDR* DRAM_BA*}]
set_multicycle_path -from [get_clocks {dram_clk_out}] -to [get_clocks {soc|altpll_0|sd1|pll7|clk[0]}] -setup -end 2


