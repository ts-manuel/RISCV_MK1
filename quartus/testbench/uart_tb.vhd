-- *********************************************************************
-- File: uart_tb.vhd
--
-- UART Test Bench
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all; 
use std.env.finish;


entity uart_tb is
end entity;


architecture behave of uart_tb is

  constant CLK_P : time := 20 ns; -- CLK 50MHz
  constant CLOC_FREQ    : integer := 50000000;
  constant BAUDRATE     : integer := 1000000;
  constant CLK_PER_BIT  : integer := 50000000 / BAUDRATE;

  signal r_clk             : std_logic := '0';

  -- UART Avalon Interface
  signal av_uart_acknowledge  : std_logic;
  signal av_uart_irq          : std_logic;
  signal av_uart_address      : std_logic_vector(2 downto 0);
  signal av_uart_bus_enable   : std_logic;
  signal av_uart_byte_enable  : std_logic_vector(3 downto 0);
  signal av_uart_rw           : std_logic;
  signal av_uart_write_data   : std_logic_vector(31 downto 0);
  signal av_uart_read_data    : std_logic_vector(31 downto 0);
  signal w_uart_RX            : std_logic := '1';
  signal w_uart_TX            : std_logic;


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

begin

  -- Clock generation
  p_clk : process
  begin
    wait for CLK_P * 0.5;
    r_clk <= not r_clk;
  end process p_clk;

  -- Simulation
  p_sim : process
  begin

    wait until falling_edge(r_clk);

    -- Test read
    av_uart_address      <= "000";
    av_uart_bus_enable   <= '1';
    av_uart_rw           <= '1';
    av_uart_byte_enable  <= "1111";
    av_uart_write_data   <= x"00000000";
    wait until falling_edge(r_clk);
    while (av_uart_acknowledge = '0') loop
      wait until falling_edge(r_clk);
    end loop;
    av_uart_bus_enable   <= '0';
    wait for CLK_P*4;

    -- Test write
    av_uart_address      <= "000";
    av_uart_bus_enable   <= '1';
    av_uart_rw           <= '0';
    av_uart_byte_enable  <= "1111";
    av_uart_write_data   <= x"0000005a";
    wait until falling_edge(r_clk);
    while (av_uart_acknowledge = '0') loop
      wait until falling_edge(r_clk);
    end loop;
    av_uart_bus_enable   <= '0';
    wait for CLK_P*4;

    wait for CLK_P*8;

    -- Drive RX signal
    w_uart_RX <= '0'; -- Start bit
    wait for CLK_P*CLK_PER_BIT;
    for i in 0 to 8 loop
      w_uart_RX <= '1';
      wait for CLK_P*CLK_PER_BIT;
    end loop;
    w_uart_RX <= '0'; -- Stop bit
    wait for CLK_P*CLK_PER_BIT;
    w_uart_RX <= '1';

    wait for CLK_P*64;

    finish;
  end process p_sim;



  uart0 : UART
    generic map (
      CLOCK_FREQUENCY =>  CLOC_FREQ,
      BAUD_RATE       =>  BAUDRATE,
      TX_FIFO_DEPTH   =>  64,
      RX_FIFO_DEPTH   =>  64
    )
    port map (
      i_clock         => r_clk,
      i_reset_n       => '1',
      --o_tx_fifo_q     : out std_logic_vector(7 downto 0);
      --o_tx_fifo_wrreq : out std_logic;
      --o_tx_fifo_rdreq : out std_logic;
      --o_tx_fifo_empty : out std_logic;
      --o_rx_sampling   : out std_logic;
      i_address       => av_uart_address,
      i_read          => av_uart_bus_enable and av_uart_rw,
      i_write         => av_uart_bus_enable and not av_uart_rw,
      i_writedata     => av_uart_write_data,
      o_readdata      => av_uart_read_data,
      o_acknowledge	  => av_uart_acknowledge,
      i_RX            => w_uart_RX,
      o_TX            => w_uart_TX
    );

end architecture behave;