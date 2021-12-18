-- *********************************************************************
-- File: decoder_tb.vhd
--
-- Program Counter Testbench
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all; 
use std.env.finish;


entity program_counter_tb is
end entity;


architecture behave of program_counter_tb is

  constant CLK_P : time := 10 ns;

  signal r_clk      : std_logic := '0';
  signal r_rst      : std_logic := '0';
  signal r_ce       : std_logic := '0';
  signal r_load     : std_logic := '0';
  signal r_value    : std_logic_vector(31 downto 0) := (others=>'0');
  signal w_pc       : std_logic_vector(31 downto 0);
  signal w_pc_next  : std_logic_vector(31 downto 0);


  type pattern_array is array (natural range <>) of std_logic_vector(31 downto 0);
  constant patterns : pattern_array := (
    x"fab8ffab",
    x"c801cb65",
    x"f242f5da",
    x"e68a2696",
    x"61a9fea9",
    x"b7bd222f",
    x"7361fb55",
    x"83ffcd90",
    x"4d452a64",
    x"38e17ba2",
    x"c1080c1c",
    x"ceee6df4",
    x"f1454dd3",
    x"bcf4a6a1",
    x"27ea601d",
    x"5a90847b"
  );


  -- converts logic vector to hex string
  function to_hstring (SLV : std_logic_vector) return string is
    variable L : LINE;
  begin
    hwrite(L,SLV);
    return L.all;
  end function to_hstring;


  component program_counter is
    port (
      i_clk     : in  std_logic;
      i_rst     : in  std_logic;
      i_ce      : in  std_logic;
      i_load    : out std_logic;
      i_value   : out std_logic_vector(31 downto 0);
      o_pc      : out std_logic_vector(31 downto 0);
      o_pc_next : out std_logic_vector(31 downto 0)
    );
  end component program_counter;

begin

  -- Clock generation
  p_clk : process
  begin
    wait for CLK_P * 0.5;
    r_clk <= not r_clk;
  end process p_clk;


  -- Apply test patterns and assert on results
  p_sim : process
    variable v_pc_exp : integer;
  begin

    -- Test reset
    r_rst     <= '1';
    r_ce      <= '0';
    r_load    <= '0';
    r_value   <= x"00000000";
    wait until rising_edge(r_clk);
    wait until rising_edge(r_clk);
    assert (w_pc      = x"00000000") severity failure;
    assert (w_pc_next = x"00000004") severity failure;
    wait until rising_edge(r_clk);
    assert (w_pc      = x"00000000") severity failure;
    assert (w_pc_next = x"00000004") severity failure;

    -- Test increment
    r_rst     <= '0';
    r_load    <= '0';
    r_value   <= x"00000000";
    v_pc_exp  := 4;
    for i in 0 to 16 loop
      r_ce      <= '1';
      wait until rising_edge(r_clk);
      r_ce      <= '0';
      wait until rising_edge(r_clk);
      assert (to_integer(unsigned(w_pc))      = v_pc_exp)       report "Increment Failed at iteration " & integer'image(i) & " PC = "       & to_hstring(w_pc)      & " EXPECTED: " & to_hstring(std_logic_vector(to_signed(v_pc_exp,   w_pc'length))) severity failure;
      assert (to_integer(unsigned(w_pc_next)) = (v_pc_exp + 4)) report "Increment Failed at iteration " & integer'image(i) & " PC_NEXT = "  & to_hstring(w_pc_next) & " EXPECTED: " & to_hstring(std_logic_vector(to_signed(v_pc_exp+4, w_pc'length))) severity failure;
      v_pc_exp  := v_pc_exp + 4;
    end loop;

    -- Test load
    r_rst     <= '0';
    for i in patterns'range loop
      r_ce      <= '1';
      r_load    <= '1';
      r_value   <= patterns(i);
      wait until rising_edge(r_clk);
      r_ce      <= '0';
      wait until rising_edge(r_clk);
      assert (w_pc = patterns(i)) report "Load Failed at iteration " & integer'image(i) & " PC = " & to_hstring(w_pc) & " EXPECTED: " & to_hstring(patterns(i)) severity failure;
    end loop;

    -- End simulation
    finish;

  end process p_sim;


  dut : program_counter
    port map (
      i_clk     => r_clk,
      i_rst     => r_rst,
      i_ce      => r_ce,
      i_load    => r_load,
      i_value   => r_value,
      o_pc      => w_pc,
      o_pc_next => w_pc_next
    );

end architecture behave;