-- *********************************************************************
-- File: avalon_bus.vhd
--
-- Stereo DAC Test Bench
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all; 
use std.env.finish;


entity stereo_dac_tb is
end entity;


architecture behave of stereo_dac_tb is

  constant CLK_P : time := 10 ns;

  signal r_clk             : std_logic := '0';
  signal w_av_acknowledge  : std_logic;
  signal w_av_irq          : std_logic;
  signal r_av_address      : std_logic_vector(2 downto 0);
  signal r_av_bus_enable   : std_logic;
  signal r_av_byte_enable  : std_logic_vector(3 downto 0);
  signal r_av_rw           : std_logic;
  signal r_av_write_data   : std_logic_vector(31 downto 0);
  signal w_av_read_data    : std_logic_vector(31 downto 0);
  signal w_left            : std_logic;
  signal w_right           : std_logic;



  component stereo_dac is
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
    r_av_address      <= "000";
    r_av_bus_enable   <= '1';
    r_av_rw           <= '1';
    r_av_byte_enable  <= "1111";
    r_av_write_data   <= x"00000000";
    wait until falling_edge(r_clk);
    while (w_av_acknowledge = '0') loop
      wait until falling_edge(r_clk);
    end loop;
    r_av_bus_enable   <= '0';
    wait for CLK_P*4;

    r_av_address      <= "100";
    r_av_bus_enable   <= '1';
    r_av_rw           <= '1';
    r_av_byte_enable  <= "1111";
    r_av_write_data   <= x"00000000";
    wait until falling_edge(r_clk);
    while (w_av_acknowledge = '0') loop
      wait until falling_edge(r_clk);
    end loop;
    r_av_bus_enable   <= '0';
    wait for CLK_P*4;

    -- Test write
    r_av_address      <= "000";
    r_av_bus_enable   <= '1';
    r_av_rw           <= '0';
    r_av_byte_enable  <= "1111";
    r_av_write_data   <= x"12345678";
    wait until falling_edge(r_clk);
    while (w_av_acknowledge = '0') loop
      wait until falling_edge(r_clk);
    end loop;
    r_av_bus_enable   <= '0';
    wait for CLK_P*4;

    r_av_address      <= "100";
    r_av_bus_enable   <= '1';
    r_av_rw           <= '0';
    r_av_byte_enable  <= "1111";
    r_av_write_data   <= x"0004ef12";
    wait until falling_edge(r_clk);
    while (w_av_acknowledge = '0') loop
      wait until falling_edge(r_clk);
    end loop;
    r_av_bus_enable   <= '0';
    wait for CLK_P*4;

    -- Test fifo write when full
    r_av_address      <= "100";
    r_av_bus_enable   <= '1';
    r_av_rw           <= '0';
    r_av_byte_enable  <= "1111";
    r_av_write_data   <= x"00020000";
    wait until falling_edge(r_clk);
    while (w_av_acknowledge = '0') loop
      wait until falling_edge(r_clk);
    end loop;
    r_av_bus_enable   <= '0';
    wait for CLK_P*4;

    for i in 0 to 64 loop
      r_av_address      <= "000";
      r_av_bus_enable   <= '1';
      r_av_rw           <= '0';
      r_av_byte_enable  <= "1111";
      r_av_write_data   <= x"ff11ff00";
      wait until falling_edge(r_clk);
      while (w_av_acknowledge = '0') loop
        wait until falling_edge(r_clk);
      end loop;
      r_av_bus_enable   <= '0';
      wait for CLK_P*4;
    end loop;

    wait for CLK_P*64;

    finish;
  end process p_sim;



  stereo_dac0 : stereo_dac
    port map (
      i_clk           => r_clk,
      av_acknowledge  => w_av_acknowledge,
      av_irq          => w_av_irq,
      av_address      => r_av_address,
      av_bus_enable   => r_av_bus_enable,
      av_byte_enable  => r_av_byte_enable,
      av_rw           => r_av_rw,
      av_write_data   => r_av_write_data,
      av_read_data    => w_av_read_data,
      o_left          => w_left,
      o_right         => w_right
    );

end architecture behave;