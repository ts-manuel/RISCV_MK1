-- *********************************************************************
-- File: alu.vhd
--
-- Arithmetic and Logic Unit.
--
-- Generic:
--
-- Port:
--  i_clk:  clock input
--  i_ce:   clock enable active HIGH
--  i_in1:  operand 1
--  i_in2:  operand 2
--  i_func: function
--  o_res:  result
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity alu is
  port (
    i_clk   : in  std_logic;
    i_ce    : in  std_logic;
    i_in1   : in  std_logic_vector(31 downto 0);
    i_in2   : in  std_logic_vector(31 downto 0);
    i_func  : in  std_logic_vector(4 downto 0);
    o_res   : out std_logic_vector(31 downto 0) := (others=>'0')
  );
end entity alu;


architecture behave of alu is

  signal w_funct : std_logic_vector(2 downto 0);
  signal w_arith : std_logic;
  signal w_bypas : std_logic;

  signal w_shift_amount : integer range 0 to 31;


begin

  w_funct <= i_func(2 downto 0);
  w_arith <= i_func(3);
  w_bypas <= i_func(4);

  w_shift_amount <= to_integer(unsigned(i_in2(4 downto 0)));

  -- Compute result
  p_alu : process (i_clk) is
  begin
    if (rising_edge(i_clk)) then
      if (i_ce = '1') then

        if (w_bypas = '1') then
          o_res <= i_in2;
        else
          case w_funct is

            -- ADD / SUB
            when "000" =>
              if (w_arith = '0') then
                o_res <= std_logic_vector(signed(i_in1) + signed(i_in2));
              else
                o_res <= std_logic_vector(signed(i_in1) - signed(i_in2));
              end if;

            -- SSL (Shift left logic)
            when "001" =>
              o_res <= std_logic_vector(shift_left(unsigned(i_in1), w_shift_amount));
            
            -- SLT (Set lower than signed)
            when "010" =>
              if (signed(i_in1) < signed(i_in2)) then
                o_res <= x"00000001";
              else
                o_res <= x"00000000";
              end if;

            -- SLTU (Set lower than unsigned)
            when "011" =>
              if (unsigned(i_in1) < unsigned(i_in2)) then
                o_res <= x"00000001";
              else
                o_res <= x"00000000";
              end if;

            -- XOR
            when "100" =>
              o_res <= i_in1 xor i_in2;

            -- SRL / SRA (Shift right logical / arithmetical)
            when "101" =>
              if (w_arith = '0') then
                o_res <= std_logic_vector(shift_right(unsigned(i_in1), w_shift_amount));
              else
                o_res <= std_logic_vector(shift_right(signed(i_in1), w_shift_amount));
              end if;

            -- OR
            when "110" =>
              o_res <= i_in1 or i_in2;

            -- AND
            when "111" =>
              o_res <= i_in1 and i_in2;

            when others =>
              o_res <= x"00000000";

          end case;
        end if;

      end if;
    end if;
  end process;

end architecture behave;