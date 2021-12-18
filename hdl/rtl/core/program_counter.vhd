-- *********************************************************************
-- File: program_counter.vhd
--
-- CPU ProgramCounter
--
-- Generic:
--
-- Port:
--  i_clk:      clock input
--  i_rst:      reset active HIGH
--  i_ce:       clock enable active HIGH
--  i_load:     when HIGH i_value is loaded into the pc
--  i_value:    branch/jump address
--  o_pc:       program counter     (synchronous)
--  o_pc_next:  program counter + 4 (combinatorial)
--
-- *********************************************************************


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity program_counter is
  port (
    i_clk     : in  std_logic;
    i_rst     : in  std_logic;
    i_ce      : in  std_logic;
    i_load    : out std_logic;
    i_value   : out std_logic_vector(31 downto 0);
    o_pc      : out std_logic_vector(31 downto 0);
    o_pc_next : out std_logic_vector(31 downto 0)
  );
end entity program_counter;


architecture behave of program_counter is
begin

  o_pc_next <= std_logic_vector(unsigned(o_pc) + to_unsigned(4, o_pc_next'length));

  p_load : process (i_clk)
  begin
    if (rising_edge(i_clk)) then
      if (i_rst = '1') then
        o_pc <= (others=>'0');
      elsif (i_ce = '1') then
        o_pc <= i_value when (i_load = '1') else o_pc_next;
      end if;
    end if;
  end process p_load;

end architecture behave;