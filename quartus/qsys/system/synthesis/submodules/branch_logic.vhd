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
    o_branch  : out std_logic := '0'
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
            if (i_in1 = i_in2) then
              o_branch <= '1';
            else
              o_branch <= '0';
            end if;

          -- BNE (Branch if i_in1 != i_in2)
          when "001" =>
            if (i_in1 /= i_in2) then
              o_branch <= '1';
            else
              o_branch <= '0';
            end if;

          -- BLT (Branch if i_in1 < i_in2) signed
          when "100" =>
            if (signed(i_in1) < signed(i_in2)) then
              o_branch <= '1';
            else
              o_branch <= '0';
            end if;

          -- BGE (Branch if i_in1 >= i_in2) signed
          when "101" =>
            if (signed(i_in1) >= signed(i_in2)) then
              o_branch <= '1';
            else
              o_branch <= '0';
            end if;

          -- BLTU (Branch if i_in1 < i_in2) unsigned
          when "110" =>
            if (unsigned(i_in1) < unsigned(i_in2)) then
              o_branch <= '1';
            else
              o_branch <= '0';
            end if;

          -- BGEU (Branch if i_in1 >= i_in2) unsigned
          when "111" =>
            if (unsigned(i_in1) >= unsigned(i_in2)) then
              o_branch <= '1';
            else
              o_branch <= '0';
            end if;

          when others =>
            o_branch <= '0';

        end case;

      end if;
    end if;
  end process p_branch;

end architecture behave;