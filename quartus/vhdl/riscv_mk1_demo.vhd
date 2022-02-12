-- *********************************************************************
-- file: riscv_mk1_demo.vhd
-- 
-- Top level module for the RISC-V MK1 Demo project
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity riscv_mk1_demo is
  port (
    -- CLOCK --
    ADC_CLK_10      : in std_logic;
    MAX10_CLK1_50   : in std_logic;
    MAX10_CLK2_50   : in std_logic;

    -- SDRAM --
    DRAM_ADDR   : out    std_logic_vector(12 downto 0);
    DRAM_BA     : out    std_logic_vector(1 downto 0);
    DRAM_CAS_N  : out    std_logic;
    DRAM_CKE    : out    std_logic;
    DRAM_CLK    : out    std_logic;
    DRAM_CS_N   : out    std_logic;
    DRAM_DQ     : inout  std_logic_vector(15 downto 0);
    DRAM_LDQM   : out    std_logic;
    DRAM_RAS_N  : out    std_logic;
    DRAM_UDQM   : out    std_logic;
    DRAM_WE_N   : out    std_logic;

    -- SEG7 --
    HEX0    : out std_logic_vector(7 downto 0);
    HEX1    : out std_logic_vector(7 downto 0);
    HEX2    : out std_logic_vector(7 downto 0);
    HEX3    : out std_logic_vector(7 downto 0);
    HEX4    : out std_logic_vector(7 downto 0);
    HEX5    : out std_logic_vector(7 downto 0);

    -- KEY --
    KEY     : in std_logic_vector(1 downto 0);

    -- LED --
    LEDR    : out std_logic_vector(9 downto 0);

    -- SW --
    SW      : in std_logic_vector(9 downto 0);

    -- VGA --
    VGA_B   : out std_logic_vector(3 downto 0);
    VGA_G   : out std_logic_vector(3 downto 0);
    VGA_HS  : out std_logic;
    VGA_R   : out std_logic_vector(3 downto 0);
    VGA_VS  : out std_logic;

    -- Arduino --
    ARDUINO_IO      : inout std_logic_vector(15 downto 0);
    ARDUINO_RESET_N : inout std_logic;

    -- GPIO, GPIO connect to GPIO Default --
    GPIO    : inout std_logic_vector(35 downto 0)
  );
end entity riscv_mk1_demo;


architecture behave of riscv_mk1_demo is

  -- Constants
  constant SYS_CLK_FREQ       : integer := 100000000;
  constant UART_BAUDRATE      : integer := 2000000;
  constant UART_TX_FIFO_SIZE  : integer := 64;
  constant UART_RX_FIFO_SIZE  : integer := 64;
  constant DAC_FIFO_SIZE      : integer := 64;
  constant VGA_FIFO_SIZE      : integer := 128;

  -- Clock and Reset
  signal w_sys_clk  : std_logic;
  signal r_reset    : std_logic := '0';
  signal r_reset0   : std_logic := '0';

  -- Stereo DAC Avalon interface
  signal av_dac_acknowledge : std_logic;
  signal av_dac_irq         : std_logic;
  signal av_dac_address     : std_logic_vector(2 downto 0);
  signal av_dac_bus_enable  : std_logic;
  signal av_dac_byte_enable : std_logic_vector(3 downto 0);
  signal av_dac_rw          : std_logic;
  signal av_dac_write_data  : std_logic_vector(31 downto 0);
  signal av_dac_read_data   : std_logic_vector(31 downto 0);
  signal w_dac_left   : std_logic;
  signal w_dac_right  : std_logic;

  -- UART Avalon Interface
  signal av_uart_acknowledge  : std_logic;
  signal av_uart_irq          : std_logic;
  signal av_uart_address      : std_logic_vector(2 downto 0);
  signal av_uart_bus_enable   : std_logic;
  signal av_uart_byte_enable  : std_logic_vector(3 downto 0);
  signal av_uart_rw           : std_logic;
  signal av_uart_write_data   : std_logic_vector(31 downto 0);
  signal av_uart_read_data    : std_logic_vector(31 downto 0);
  signal w_uart_RX            : std_logic;
  signal w_uart_TX            : std_logic;

  -- VGA Avalon Interface
  signal av_vga_acknowledge  : std_logic;
  signal av_vga_irq          : std_logic;
  signal av_vga_address      : std_logic_vector(3 downto 0);
  signal av_vga_bus_enable   : std_logic;
  signal av_vga_byte_enable  : std_logic_vector(3 downto 0);
  signal av_vga_rw           : std_logic;
  signal av_vga_write_data   : std_logic_vector(31 downto 0);
  signal av_vga_read_data    : std_logic_vector(31 downto 0);
  
  component system is
    port (
      clk_clk     : in  std_logic;
		  rst_reset_n : in  std_logic;
      sys_clk     : out   std_logic;
		  clk_sdram_clk : out   std_logic;
		  sdram_addr    : out   std_logic_vector(12 downto 0);
		  sdram_ba      : out   std_logic_vector(1 downto 0);
		  sdram_cas_n   : out   std_logic;
		  sdram_cke     : out   std_logic;
		  sdram_cs_n    : out   std_logic;
		  sdram_dq      : inout std_logic_vector(15 downto 0);
		  sdram_dqm     : out   std_logic_vector(1 downto 0);
		  sdram_ras_n   : out   std_logic;
		  sdram_we_n    : out   std_logic;
      av_dac_external_interface_acknowledge   : in    std_logic;
		  av_dac_external_interface_irq           : in    std_logic;
		  av_dac_external_interface_address       : out   std_logic_vector(2 downto 0);
		  av_dac_external_interface_bus_enable    : out   std_logic;
		  av_dac_external_interface_byte_enable   : out   std_logic_vector(3 downto 0);
		  av_dac_external_interface_rw            : out   std_logic;
		  av_dac_external_interface_write_data    : out   std_logic_vector(31 downto 0);
		  av_dac_external_interface_read_data     : in    std_logic_vector(31 downto 0);
      av_uart_external_interface_acknowledge  : in    std_logic;
      av_uart_external_interface_irq          : in    std_logic;
      av_uart_external_interface_address      : out   std_logic_vector(2 downto 0);
      av_uart_external_interface_bus_enable   : out   std_logic;
      av_uart_external_interface_byte_enable  : out   std_logic_vector(3 downto 0);
      av_uart_external_interface_rw           : out   std_logic;
      av_uart_external_interface_write_data   : out   std_logic_vector(31 downto 0);
      av_uart_external_interface_read_data    : in    std_logic_vector(31 downto 0);
      av_vga_external_interface_acknowledge   : in    std_logic;
      av_vga_external_interface_irq           : in    std_logic;
      av_vga_external_interface_address       : out   std_logic_vector(3 downto 0);
      av_vga_external_interface_bus_enable    : out   std_logic;
      av_vga_external_interface_byte_enable   : out   std_logic_vector(3 downto 0);
      av_vga_external_interface_rw            : out   std_logic;
      av_vga_external_interface_write_data    : out   std_logic_vector(31 downto 0);
      av_vga_external_interface_read_data     : in    std_logic_vector(31 downto 0);
      disp0_export  : out   std_logic_vector(7 downto 0);
		  disp1_export  : out   std_logic_vector(7 downto 0);
		  disp2_export  : out   std_logic_vector(7 downto 0);
		  disp3_export  : out   std_logic_vector(7 downto 0);
		  disp4_export  : out   std_logic_vector(7 downto 0);
		  disp5_export  : out   std_logic_vector(7 downto 0);
      leds_export   : out std_logic_vector(9 downto 0)
    );
  end component system;

  component stereo_dac is
    generic (
      FIFO_SIZE       : integer
    );
    port (
      i_clk           : in  std_logic;
      av_acknowledge  : out std_logic;
      av_irq          : out std_logic;
      av_address      : in  std_logic_vector(2 downto 0);
      av_bus_enable   : in  std_logic;
      av_byte_enable  : in  std_logic_vector(3 downto 0);
      av_rw           : in  std_logic;
      av_write_data   : in  std_logic_vector(31 downto 0);
      av_read_data    : out std_logic_vector(31 downto 0);
      o_left          : out std_logic;
      o_right         : out std_logic
    );
  end component stereo_dac;


  component UART is
    generic (
	    CLOCK_FREQUENCY : integer;
	    BAUD_RATE       : integer;
	    TX_FIFO_DEPTH   : integer;
	    RX_FIFO_DEPTH   : integer
	  );
    port (
	    i_clock         : in  std_logic;
	    i_reset_n       : in  std_logic;
      o_tx_fifo_q     : out std_logic_vector(7 downto 0);
      o_tx_fifo_wrreq : out std_logic;
      o_tx_fifo_rdreq : out std_logic;
      o_tx_fifo_empty : out std_logic;
      o_rx_sampling   : out std_logic;
      i_address       : in  std_logic_vector(2 downto 0);
      i_read          : in  std_logic;
      i_write         : in  std_logic;
      i_writedata     : in  std_logic_vector(31 downto 0);
      o_readdata      : out std_logic_vector(31 downto 0);
      o_acknowledge	  : out std_logic;
      i_RX            : in  std_logic;
      o_TX            : out std_logic
	  );
  end component UART;

  component video_gen is
    generic (
      FIFO_SIZE : integer
    );
    port (
      i_clk           : in  std_logic;
      av_acknowledge  : out std_logic;
      av_irq          : out std_logic;
      av_address      : in  std_logic_vector(3 downto 0);
      av_bus_enable   : in  std_logic;
      av_byte_enable  : in  std_logic_vector(3 downto 0);
      av_rw           : in  std_logic;
      av_write_data   : in  std_logic_vector(31 downto 0);
      av_read_data    : out std_logic_vector(31 downto 0);
      o_vga_r         : out std_logic_vector(3 downto 0);
      o_vga_g         : out std_logic_vector(3 downto 0);
      o_vga_b         : out std_logic_vector(3 downto 0);
      o_vga_hs        : out std_logic;
      o_vga_vs        : out std_logic
    );
  end component video_gen;

begin

  ARDUINO_IO(12) <= w_dac_left;
  ARDUINO_IO(13) <= w_dac_right;

  GPIO(0)   <= 'Z';
  w_uart_RX <= GPIO(0);
  GPIO(1)   <= w_uart_TX;

  av_uart_irq <= '0';
  
  -- Sinchronize inputs
  p_sync : process (MAX10_CLK1_50)
  begin
    if rising_edge(MAX10_CLK1_50) then
      r_reset0  <= not KEY(0);
      r_reset   <= r_reset0;
    end if;
  end process p_sync;


  soc : system
    port map (
      clk_clk       => MAX10_CLK1_50,
      rst_reset_n   => not r_reset,
      sys_clk       => w_sys_clk,

      clk_sdram_clk => DRAM_CLK,
		  sdram_addr    => DRAM_ADDR,
		  sdram_ba      => DRAM_BA,
		  sdram_cas_n   => DRAM_CAS_N,
		  sdram_cke     => DRAM_CKE,
		  sdram_cs_n    => DRAM_CS_N,
		  sdram_dq      => DRAM_DQ,
		  sdram_dqm(0)  => DRAM_LDQM,
		  sdram_dqm(1)  => DRAM_UDQM,
		  sdram_ras_n   => DRAM_RAS_N,
		  sdram_we_n    => DRAM_WE_N,

      av_dac_external_interface_acknowledge => av_dac_acknowledge,
		  av_dac_external_interface_irq         => av_dac_irq,
		  av_dac_external_interface_address     => av_dac_address,
		  av_dac_external_interface_bus_enable  => av_dac_bus_enable,
		  av_dac_external_interface_byte_enable => av_dac_byte_enable,
		  av_dac_external_interface_rw          => av_dac_rw,
		  av_dac_external_interface_write_data  => av_dac_write_data,
		  av_dac_external_interface_read_data   => av_dac_read_data,

      av_uart_external_interface_acknowledge  => av_uart_acknowledge,
      av_uart_external_interface_irq          => av_uart_irq,
      av_uart_external_interface_address      => av_uart_address,
      av_uart_external_interface_bus_enable   => av_uart_bus_enable,
      av_uart_external_interface_byte_enable  => av_uart_byte_enable,
      av_uart_external_interface_rw           => av_uart_rw,
      av_uart_external_interface_write_data   => av_uart_write_data,
      av_uart_external_interface_read_data    => av_uart_read_data,

      av_vga_external_interface_acknowledge   => av_vga_acknowledge,
      av_vga_external_interface_irq           => av_vga_irq,
      av_vga_external_interface_address       => av_vga_address,
      av_vga_external_interface_bus_enable    => av_vga_bus_enable,
      av_vga_external_interface_byte_enable   => av_vga_byte_enable,
      av_vga_external_interface_rw            => av_vga_rw,
      av_vga_external_interface_write_data    => av_vga_write_data,
      av_vga_external_interface_read_data     => av_vga_read_data,

      disp0_export  => HEX0,
      disp1_export  => HEX1,
      disp2_export  => HEX2,
      disp3_export  => HEX3,
      disp4_export  => HEX4,
      disp5_export  => HEX5,

      leds_export => LEDR
    );


  stereo_dac0 : stereo_dac
    generic map(
      FIFO_SIZE       => DAC_FIFO_SIZE
    )
    port map(
      i_clk           => w_sys_clk,
      av_acknowledge  => av_dac_acknowledge,
      av_irq          => av_dac_irq,
      av_address      => av_dac_address,
      av_bus_enable   => av_dac_bus_enable,
      av_byte_enable  => av_dac_byte_enable,
      av_rw           => av_dac_rw,
      av_write_data   => av_dac_write_data,
      av_read_data    => av_dac_read_data,
      o_left          => w_dac_left,
      o_right         => w_dac_right
    );

  uart0 : UART
    generic map (
      CLOCK_FREQUENCY =>  SYS_CLK_FREQ,
      BAUD_RATE       =>  UART_BAUDRATE,
      TX_FIFO_DEPTH   =>  UART_TX_FIFO_SIZE,
      RX_FIFO_DEPTH   =>  UART_RX_FIFO_SIZE
    )
    port map (
      i_clock         => w_sys_clk,
      i_reset_n       => not r_reset,
      i_address       => av_uart_address,
      i_read          => av_uart_bus_enable and av_uart_rw,
      i_write         => av_uart_bus_enable and not av_uart_rw,
      i_writedata     => av_uart_write_data,
      o_readdata      => av_uart_read_data,
      o_acknowledge	  => av_uart_acknowledge,
      i_RX            => w_uart_RX,
      o_TX            => w_uart_TX
    );


  video_gen0 : video_gen
    generic map (
      FIFO_SIZE       => VGA_FIFO_SIZE
    )
    port map (
      i_clk           => w_sys_clk,
      av_acknowledge  => av_vga_acknowledge,
      av_irq          => av_vga_irq,
      av_address      => av_vga_address,
      av_bus_enable   => av_vga_bus_enable,
      av_byte_enable  => av_vga_byte_enable,
      av_rw           => av_vga_rw,
      av_write_data   => av_vga_write_data,
      av_read_data    => av_vga_read_data,
      o_vga_r         => VGA_R,
      o_vga_g         => VGA_G,
      o_vga_b         => VGA_B,
      o_vga_hs        => VGA_HS,
      o_vga_vs        => VGA_VS
    );

end architecture behave;
