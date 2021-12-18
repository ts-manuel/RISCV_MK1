-- *********************************************************************
-- File: control_logic_tb.vhd
--
-- Control Logic Testbench
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all; 
use std.env.finish;


entity control_unit_tb is
end entity;


architecture behave of control_unit_tb is

  constant CLK_P : time := 10 ns;

  signal r_clk         : std_logic := '0';
  signal r_rst         : std_logic := '0';
  signal r_fetch_wait  : std_logic := '0';
  signal r_memory_wait : std_logic := '0';
  signal w_fetch       : std_logic;
  signal w_decode      : std_logic;
  signal w_execute     : std_logic;
  signal w_memory      : std_logic;
  signal w_write_back  : std_logic;


  component control_unit is
    port (
      i_clk         : in  std_logic;
      i_rst         : in  std_logic;
      i_fetch_wait  : in  std_logic;
      i_memory_wait : in  std_logic;
      o_fetch       : out std_logic;
      o_decode      : out std_logic;
      o_execute     : out std_logic;
      o_memory      : out std_logic;
      o_write_back  : out std_logic
    );
  end component control_unit;

begin


  -- Clock generation
  p_clk : process
  begin
    wait for CLK_P * 0.5;
    r_clk <= not r_clk;
  end process p_clk;


  -- Apply test patterns and assert on results
  p_sim : process
  begin

    -- Test reset state
    r_rst         <= '1';
    r_fetch_wait  <= '0';
    r_memory_wait <= '0';
    wait until rising_edge(r_clk);
    assert w_fetch      = '0' severity failure;
    assert w_decode     = '0' severity failure;
    assert w_execute    = '0' severity failure;
    assert w_memory     = '0' severity failure;
    assert w_write_back = '0' severity failure;

    -- Test sequence with no wait states
    r_rst         <= '0';
    r_fetch_wait  <= '0';
    r_memory_wait <= '0';
    wait until rising_edge(r_clk);
    assert w_fetch      = '1' severity failure;
    assert w_decode     = '1' severity failure;
    assert w_execute    = '0' severity failure;
    assert w_memory     = '0' severity failure;
    assert w_write_back = '0' severity failure;
    wait until rising_edge(r_clk);
    assert w_fetch      = '0' severity failure;
    assert w_decode     = '0' severity failure;
    assert w_execute    = '1' severity failure;
    assert w_memory     = '0' severity failure;
    assert w_write_back = '0' severity failure;
    wait until rising_edge(r_clk);
    assert w_fetch      = '0' severity failure;
    assert w_decode     = '0' severity failure;
    assert w_execute    = '0' severity failure;
    assert w_memory     = '1' severity failure;
    assert w_write_back = '1' severity failure;
    wait until rising_edge(r_clk);
    assert w_fetch      = '1' severity failure;
    assert w_decode     = '1' severity failure;
    assert w_execute    = '0' severity failure;
    assert w_memory     = '0' severity failure;
    assert w_write_back = '0' severity failure;
    wait until rising_edge(r_clk);
    assert w_fetch      = '0' severity failure;
    assert w_decode     = '0' severity failure;
    assert w_execute    = '1' severity failure;
    assert w_memory     = '0' severity failure;
    assert w_write_back = '0' severity failure;
    wait until rising_edge(r_clk);
    assert w_fetch      = '0' severity failure;
    assert w_decode     = '0' severity failure;
    assert w_execute    = '0' severity failure;
    assert w_memory     = '1' severity failure;
    assert w_write_back = '1' severity failure;

    -- Test fetch wait states
    r_fetch_wait  <= '1';
    r_memory_wait <= '0';
    wait until rising_edge(r_clk);
    assert w_fetch      = '1' severity failure;
    assert w_decode     = '0' severity failure;
    assert w_execute    = '0' severity failure;
    assert w_memory     = '0' severity failure;
    assert w_write_back = '0' severity failure;
    wait until rising_edge(r_clk);
    assert w_fetch      = '1' severity failure;
    assert w_decode     = '0' severity failure;
    assert w_execute    = '0' severity failure;
    assert w_memory     = '0' severity failure;
    assert w_write_back = '0' severity failure;
    wait until falling_edge(r_clk);
    r_fetch_wait  <= '0';
    wait until rising_edge(r_clk);
    assert w_fetch      = '1' severity failure;
    assert w_decode     = '1' severity failure;
    assert w_execute    = '0' severity failure;
    assert w_memory     = '0' severity failure;
    assert w_write_back = '0' severity failure;
    wait until rising_edge(r_clk);
    assert w_fetch      = '0' severity failure;
    assert w_decode     = '0' severity failure;
    assert w_execute    = '1' severity failure;
    assert w_memory     = '0' severity failure;
    assert w_write_back = '0' severity failure;
    wait until rising_edge(r_clk);
    assert w_fetch      = '0' severity failure;
    assert w_decode     = '0' severity failure;
    assert w_execute    = '0' severity failure;
    assert w_memory     = '1' severity failure;
    assert w_write_back = '1' severity failure;

    -- Test memory wait states
    wait until rising_edge(r_clk);
    assert w_fetch      = '1' severity failure;
    assert w_decode     = '1' severity failure;
    assert w_execute    = '0' severity failure;
    assert w_memory     = '0' severity failure;
    assert w_write_back = '0' severity failure;
    wait until rising_edge(r_clk);
    assert w_fetch      = '0' severity failure;
    assert w_decode     = '0' severity failure;
    assert w_execute    = '1' severity failure;
    assert w_memory     = '0' severity failure;
    assert w_write_back = '0' severity failure;
    r_fetch_wait  <= '0';
    r_memory_wait <= '1';
    wait until rising_edge(r_clk);
    assert w_fetch      = '0' severity failure;
    assert w_decode     = '0' severity failure;
    assert w_execute    = '0' severity failure;
    assert w_memory     = '1' severity failure;
    assert w_write_back = '0' severity failure;
    wait until rising_edge(r_clk);
    assert w_fetch      = '0' severity failure;
    assert w_decode     = '0' severity failure;
    assert w_execute    = '0' severity failure;
    assert w_memory     = '1' severity failure;
    assert w_write_back = '0' severity failure;
    wait until falling_edge(r_clk);
    r_memory_wait  <= '0';
    wait until rising_edge(r_clk);
    assert w_fetch      = '0' severity failure;
    assert w_decode     = '0' severity failure;
    assert w_execute    = '0' severity failure;
    assert w_memory     = '1' severity failure;
    assert w_write_back = '1' severity failure;

    wait until rising_edge(r_clk);
    assert w_fetch      = '1' severity failure;
    assert w_decode     = '1' severity failure;
    assert w_execute    = '0' severity failure;
    assert w_memory     = '0' severity failure;
    assert w_write_back = '0' severity failure;

    -- End simulation
    finish;

  end process p_sim;


  dut : control_unit
    port map (
      i_clk         => r_clk,
      i_rst         => r_rst,
      i_fetch_wait  => r_fetch_wait,
      i_memory_wait => r_memory_wait,
      o_fetch       => w_fetch,
      o_decode      => w_decode,
      o_execute     => w_execute,
      o_memory      => w_memory,
      o_write_back  => w_write_back
    );

end architecture behave;