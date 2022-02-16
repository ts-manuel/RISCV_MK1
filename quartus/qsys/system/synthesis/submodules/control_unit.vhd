-- *********************************************************************
-- File: control_unit.vhd
--
-- CPU Control Unit
--
-- Generic:
--
-- Port:
--  i_clk:          clock input
--  i_rst:          active HIGH reset signal
--  i_fetch_wait:   wait signal from code memory
--  i_memory_wait:  wait signal from data memory
--  o_fetch:        fetch enable signal
--  o_decode:       decode enable signal
--  o_execute:      execute enable signal
--  o_memory:       memory enable signal
--  o_write_back:   write back enable signal
--
-- *********************************************************************


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity control_unit is
  port (
    i_clk         : in      std_logic;
    i_rst         : in      std_logic;
    i_fetch_wait  : in      std_logic;
    i_memory_wait : in      std_logic;
    o_fetch       : buffer  std_logic;
    o_decode      : out     std_logic;
    o_execute     : out     std_logic;
    o_memory      : buffer  std_logic;
    o_write_back  : out     std_logic
  );
end entity control_unit;


architecture behave of control_unit is

  signal r_fetch    : std_logic := '1';
  signal r_execute  : std_logic := '0';
  signal r_memory   : std_logic := '0';

begin

  o_fetch       <= '0' when (i_rst = '1')                           else r_fetch;
  o_decode      <= '1' when (o_fetch = '1' and i_fetch_wait ='0')   else '0';
  o_execute     <= r_execute;
  o_memory      <= r_memory;
  o_write_back  <= '1' when (o_memory = '1' and i_memory_wait ='0') else '0';

  p_control : process (i_clk)
  begin
    if (rising_edge(i_clk)) then
      if (i_rst = '1') then
        r_fetch   <= '1';
        r_execute <= '0';
        r_memory  <= '0';
      elsif (i_fetch_wait = '0' and i_memory_wait = '0') then
        r_fetch   <= r_memory;
        r_execute <= r_fetch;
        r_memory  <= r_execute;
      end if;
    end if;
  end process p_control;

end architecture behave;