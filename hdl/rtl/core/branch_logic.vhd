-- *********************************************************************
-- File: branch_logic.vhd
--
-- CPU Branch logic
--
-- Generic:
--
-- Port:
--  i_clk:    clock input
--  i_ce:     clock enable active HIGH
--  i_in1:    operand 1
--  i_in2:    operand 2
--  i_func:   function
--  o_branch: result
--
-- *********************************************************************


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity branch_logic is
  port (
    i_clk     : in std_logic;
    i_ce      : in std_logic;
    i_in1     : in std_logic_vector(31 downto 0);
    i_in2     : in std_logic_vector(31 downto 0);
    i_func    : in std_logic_vector(2 downto 0);
    o_branch  : out std_logic
  );
end entity branch_logic;


architecture behave of branch_logic is

begin

  p_branch : process (i_clk)
  begin
    if (rising_edge(i_clk)) then
      if (i_ce = '1') then

        case i_func is

          -- BEQ (Branch if i_in1 == i_in2)
          when "000" =>
            o_branch <= '1' when (i_in1 = i_in2) else '0';

          -- BNE (Branch if i_in1 != i_in2)
          when "001" =>
            o_branch <= '1' when (i_in1 /= i_in2) else '0';

          -- BLT (Branch if i_in1 < i_in2) signed
          when "100" =>
            o_branch <= '1' when (signed(i_in1) < signed(i_in2)) else '0';

          -- BGE (Branch if i_in1 >= i_in2) signed
          when "101" =>
            o_branch <= '1' when (signed(i_in1) >= signed(i_in2)) else '0';

          -- BLTU (Branch if i_in1 < i_in2) unsigned
          when "110" =>
            o_branch <= '1' when (unsigned(i_in1) < unsigned(i_in2)) else '0';

          -- BGEU (Branch if i_in1 >= i_in2) unsigned
          when "111" =>
            o_branch <= '1' when (unsigned(i_in1) >= unsigned(i_in2)) else '0';

          when others =>
            o_branch <= '0';

        end case;

      end if;
    end if;
  end process p_branch;

end architecture behave;