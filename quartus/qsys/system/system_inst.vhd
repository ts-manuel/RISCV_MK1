	component system is
		port (
			av_dac_external_interface_acknowledge  : in    std_logic                     := 'X';             -- acknowledge
			av_dac_external_interface_irq          : in    std_logic                     := 'X';             -- irq
			av_dac_external_interface_address      : out   std_logic_vector(2 downto 0);                     -- address
			av_dac_external_interface_bus_enable   : out   std_logic;                                        -- bus_enable
			av_dac_external_interface_byte_enable  : out   std_logic_vector(3 downto 0);                     -- byte_enable
			av_dac_external_interface_rw           : out   std_logic;                                        -- rw
			av_dac_external_interface_write_data   : out   std_logic_vector(31 downto 0);                    -- write_data
			av_dac_external_interface_read_data    : in    std_logic_vector(31 downto 0) := (others => 'X'); -- read_data
			av_uart_external_interface_acknowledge : in    std_logic                     := 'X';             -- acknowledge
			av_uart_external_interface_irq         : in    std_logic                     := 'X';             -- irq
			av_uart_external_interface_address     : out   std_logic_vector(2 downto 0);                     -- address
			av_uart_external_interface_bus_enable  : out   std_logic;                                        -- bus_enable
			av_uart_external_interface_byte_enable : out   std_logic_vector(3 downto 0);                     -- byte_enable
			av_uart_external_interface_rw          : out   std_logic;                                        -- rw
			av_uart_external_interface_write_data  : out   std_logic_vector(31 downto 0);                    -- write_data
			av_uart_external_interface_read_data   : in    std_logic_vector(31 downto 0) := (others => 'X'); -- read_data
			av_vga_external_interface_acknowledge  : in    std_logic                     := 'X';             -- acknowledge
			av_vga_external_interface_irq          : in    std_logic                     := 'X';             -- irq
			av_vga_external_interface_address      : out   std_logic_vector(3 downto 0);                     -- address
			av_vga_external_interface_bus_enable   : out   std_logic;                                        -- bus_enable
			av_vga_external_interface_byte_enable  : out   std_logic_vector(3 downto 0);                     -- byte_enable
			av_vga_external_interface_rw           : out   std_logic;                                        -- rw
			av_vga_external_interface_write_data   : out   std_logic_vector(31 downto 0);                    -- write_data
			av_vga_external_interface_read_data    : in    std_logic_vector(31 downto 0) := (others => 'X'); -- read_data
			clk_clk                                : in    std_logic                     := 'X';             -- clk
			clk_sdram_clk                          : out   std_logic;                                        -- clk
			disp0_export                           : out   std_logic_vector(7 downto 0);                     -- export
			disp1_export                           : out   std_logic_vector(7 downto 0);                     -- export
			disp2_export                           : out   std_logic_vector(7 downto 0);                     -- export
			disp3_export                           : out   std_logic_vector(7 downto 0);                     -- export
			disp4_export                           : out   std_logic_vector(7 downto 0);                     -- export
			disp5_export                           : out   std_logic_vector(7 downto 0);                     -- export
			leds_export                            : out   std_logic_vector(9 downto 0);                     -- export
			rst_reset_n                            : in    std_logic                     := 'X';             -- reset_n
			sdram_addr                             : out   std_logic_vector(12 downto 0);                    -- addr
			sdram_ba                               : out   std_logic_vector(1 downto 0);                     -- ba
			sdram_cas_n                            : out   std_logic;                                        -- cas_n
			sdram_cke                              : out   std_logic;                                        -- cke
			sdram_cs_n                             : out   std_logic;                                        -- cs_n
			sdram_dq                               : inout std_logic_vector(15 downto 0) := (others => 'X'); -- dq
			sdram_dqm                              : out   std_logic_vector(1 downto 0);                     -- dqm
			sdram_ras_n                            : out   std_logic;                                        -- ras_n
			sdram_we_n                             : out   std_logic;                                        -- we_n
			sys_clk                                : out   std_logic                                         -- clk
		);
	end component system;

	u0 : component system
		port map (
			av_dac_external_interface_acknowledge  => CONNECTED_TO_av_dac_external_interface_acknowledge,  --  av_dac_external_interface.acknowledge
			av_dac_external_interface_irq          => CONNECTED_TO_av_dac_external_interface_irq,          --                           .irq
			av_dac_external_interface_address      => CONNECTED_TO_av_dac_external_interface_address,      --                           .address
			av_dac_external_interface_bus_enable   => CONNECTED_TO_av_dac_external_interface_bus_enable,   --                           .bus_enable
			av_dac_external_interface_byte_enable  => CONNECTED_TO_av_dac_external_interface_byte_enable,  --                           .byte_enable
			av_dac_external_interface_rw           => CONNECTED_TO_av_dac_external_interface_rw,           --                           .rw
			av_dac_external_interface_write_data   => CONNECTED_TO_av_dac_external_interface_write_data,   --                           .write_data
			av_dac_external_interface_read_data    => CONNECTED_TO_av_dac_external_interface_read_data,    --                           .read_data
			av_uart_external_interface_acknowledge => CONNECTED_TO_av_uart_external_interface_acknowledge, -- av_uart_external_interface.acknowledge
			av_uart_external_interface_irq         => CONNECTED_TO_av_uart_external_interface_irq,         --                           .irq
			av_uart_external_interface_address     => CONNECTED_TO_av_uart_external_interface_address,     --                           .address
			av_uart_external_interface_bus_enable  => CONNECTED_TO_av_uart_external_interface_bus_enable,  --                           .bus_enable
			av_uart_external_interface_byte_enable => CONNECTED_TO_av_uart_external_interface_byte_enable, --                           .byte_enable
			av_uart_external_interface_rw          => CONNECTED_TO_av_uart_external_interface_rw,          --                           .rw
			av_uart_external_interface_write_data  => CONNECTED_TO_av_uart_external_interface_write_data,  --                           .write_data
			av_uart_external_interface_read_data   => CONNECTED_TO_av_uart_external_interface_read_data,   --                           .read_data
			av_vga_external_interface_acknowledge  => CONNECTED_TO_av_vga_external_interface_acknowledge,  --  av_vga_external_interface.acknowledge
			av_vga_external_interface_irq          => CONNECTED_TO_av_vga_external_interface_irq,          --                           .irq
			av_vga_external_interface_address      => CONNECTED_TO_av_vga_external_interface_address,      --                           .address
			av_vga_external_interface_bus_enable   => CONNECTED_TO_av_vga_external_interface_bus_enable,   --                           .bus_enable
			av_vga_external_interface_byte_enable  => CONNECTED_TO_av_vga_external_interface_byte_enable,  --                           .byte_enable
			av_vga_external_interface_rw           => CONNECTED_TO_av_vga_external_interface_rw,           --                           .rw
			av_vga_external_interface_write_data   => CONNECTED_TO_av_vga_external_interface_write_data,   --                           .write_data
			av_vga_external_interface_read_data    => CONNECTED_TO_av_vga_external_interface_read_data,    --                           .read_data
			clk_clk                                => CONNECTED_TO_clk_clk,                                --                        clk.clk
			clk_sdram_clk                          => CONNECTED_TO_clk_sdram_clk,                          --                  clk_sdram.clk
			disp0_export                           => CONNECTED_TO_disp0_export,                           --                      disp0.export
			disp1_export                           => CONNECTED_TO_disp1_export,                           --                      disp1.export
			disp2_export                           => CONNECTED_TO_disp2_export,                           --                      disp2.export
			disp3_export                           => CONNECTED_TO_disp3_export,                           --                      disp3.export
			disp4_export                           => CONNECTED_TO_disp4_export,                           --                      disp4.export
			disp5_export                           => CONNECTED_TO_disp5_export,                           --                      disp5.export
			leds_export                            => CONNECTED_TO_leds_export,                            --                       leds.export
			rst_reset_n                            => CONNECTED_TO_rst_reset_n,                            --                        rst.reset_n
			sdram_addr                             => CONNECTED_TO_sdram_addr,                             --                      sdram.addr
			sdram_ba                               => CONNECTED_TO_sdram_ba,                               --                           .ba
			sdram_cas_n                            => CONNECTED_TO_sdram_cas_n,                            --                           .cas_n
			sdram_cke                              => CONNECTED_TO_sdram_cke,                              --                           .cke
			sdram_cs_n                             => CONNECTED_TO_sdram_cs_n,                             --                           .cs_n
			sdram_dq                               => CONNECTED_TO_sdram_dq,                               --                           .dq
			sdram_dqm                              => CONNECTED_TO_sdram_dqm,                              --                           .dqm
			sdram_ras_n                            => CONNECTED_TO_sdram_ras_n,                            --                           .ras_n
			sdram_we_n                             => CONNECTED_TO_sdram_we_n,                             --                           .we_n
			sys_clk                                => CONNECTED_TO_sys_clk                                 --                        sys.clk
		);

