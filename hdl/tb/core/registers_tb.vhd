-- *********************************************************************
-- File: registers_tb.vhd
--
-- CPU register file testbench
-- 32 registers, r0 hardwired to 0.
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;


entity registers_tb is
end entity;


architecture behave of registers_tb is

  constant CLK_P : time := 10 ns;

  signal r_clk    : std_logic := '0';
  signal r_ce     : std_logic := '0';
  signal r_rs1    : std_logic_vector(4 downto 0)  := (others=>'0');
  signal r_rs2    : std_logic_vector(4 downto 0)  := (others=>'0');
  signal r_rd     : std_logic_vector(4 downto 0)  := (others=>'0');
  signal r_value  : std_logic_vector(31 downto 0) := (others=>'0');
  signal w_reg1   : std_logic_vector(31 downto 0);
  signal w_reg2   : std_logic_vector(31 downto 0);


  component registers is
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
  end component registers;

begin

  -- Clock generation
  p_clk : process
  begin
    wait for CLK_P * 0.5;
    r_clk <= not r_clk;
  end process p_clk;


  -- Write to all registers and read back the sored values from both ports
  p_sim : process
    variable v_data : std_logic_vector(31 downto 0) := x"0055aaff";
  begin

    for i in 0 to 31 loop
      -- Write register
      r_ce    <= '1';
      r_rd    <= std_logic_vector(to_unsigned(i, r_rd'length));
      r_value <= v_data;
      wait until rising_edge(r_clk);
      r_ce    <= '0';

      -- Read on port 1
      r_rs1 <= std_logic_vector(to_unsigned(i, r_rs1'length));
      r_rs2 <= (others=>'0');
      wait until rising_edge(r_clk);
      if (i = 0) then
        assert w_reg1 = x"00000000" severity failure;
      else
        assert w_reg1 = v_data severity failure;
      end if;
      assert w_reg2 = x"00000000" severity failure;

      -- Read on port 2
      r_rs1 <= (others=>'0');
      r_rs2 <= std_logic_vector(to_unsigned(i, r_rs2'length));
      wait until rising_edge(r_clk);
      assert w_reg1 = x"00000000" severity failure;
      if (i = 0) then
        assert w_reg2 = x"00000000" severity failure;
      else
        assert w_reg2 = v_data severity failure;
      end if;

      v_data := v_data(v_data'length - 2 downto 0) & v_data(v_data'length - 1);
    end loop;

    -- End simulation
    finish;

  end process p_sim;


  regs : registers
    port map (
      i_clk   => r_clk,
      i_ce    => r_ce,
      i_rs1   => r_rs1,
      i_rs2   => r_rs2,
      i_rd    => r_rd,
      i_value => r_value,
      o_reg1  => w_reg1,
      o_reg2  => w_reg2
    );

end architecture behave;
