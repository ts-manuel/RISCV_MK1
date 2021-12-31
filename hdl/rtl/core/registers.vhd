-- *********************************************************************
-- File: registers.vhd
--
-- CPU register file.
-- 32 registers, r0 hardwired to 0.
--
-- Generic:
--
-- Port:
--  i_clk:    clock input
--  i_ce:     clock enable, when HIGH i_value is copied to the destination register
--  i_rs1:    source register 1
--  i_rs2:    source register 2
--  i_rd:     destination register
--  i_value:  value to be written in the destinationregister
--  o_reg1:   content of the register selected with i_rs1
--  o_reg2:   content of the register selected with i_rs2
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity registers is
  port (
    i_clk   : in  std_logic;
    i_ce    : in  std_logic;
    i_rs1   : in  std_logic_vector(4 downto 0);
    i_rs2   : in  std_logic_vector(4 downto 0);
    i_rd    : in  std_logic_vector(4 downto 0);
    i_value : in  std_logic_vector(31 downto 0);
    o_reg1  : out std_logic_vector(31 downto 0);
    o_reg2  : out std_logic_vector(31 downto 0)
  );
end entity registers;


architecture behave of registers is

  -- Register Array
  type t_Memory is array (1 to 31) of std_logic_vector(31 downto 0);
  signal r_regs : t_Memory;

  signal w_rs1 : integer range 0 to 31;
  signal w_rs2 : integer range 0 to 31;
  signal w_rd  : integer range 0 to 31;

begin

  w_rs1   <= to_integer(unsigned(i_rs1));
  w_rs2   <= to_integer(unsigned(i_rs2));
  w_rd    <= to_integer(unsigned(i_rd));

  -- Output selected registers
  o_reg1  <= x"00000000" when (w_rs1 = 0) else r_regs(w_rs1);
  o_reg2  <= x"00000000" when (w_rs2 = 0) else r_regs(w_rs2);

  -- Write to destination register
  p_reg_write : process (i_clk)
  begin
    if (rising_edge(i_clk)) then
      if (i_ce) then
        if (w_rd /= 0) then
          r_regs(w_rd) <= i_value;
        end if;
      end if;
    end if;
  end process p_reg_write;

end architecture behave;