-- *********************************************************************
-- File: branch_logic_tb.vhd
--
-- Branch logic Testbench
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all; 
use std.env.finish;


entity branch_logic_tb is
end entity;


architecture behave of branch_logic_tb is

  constant CLK_P : time := 10 ns;

  signal r_clk    : std_logic                      := '0';
  signal r_ce     : std_logic                      := '0';
  signal r_in1    : std_logic_vector(31 downto 0)  := (others=>'0');
  signal r_in2    : std_logic_vector(31 downto 0)  := (others=>'0');
  signal r_func   : std_logic_vector(2  downto 0)  := (others=>'0');
  signal w_branch : std_logic;

  -- Test patters to apply
  type pattern_type is record
    in1     : std_logic_vector(31 downto 0);
    in2     : std_logic_vector(31 downto 0);
    func    : std_logic_vector(2  downto 0);
    branch  : std_logic;
  end record;
  type pattern_array is array (natural range <>) of pattern_type;
  constant patterns : pattern_array := (
    -- BEQ (Branch if in1 = in2)
    (x"93d506d7", x"5181797a", "000", '0'),
    (x"a58c36a2", x"e342ed0d", "000", '0'),
    (x"92e66a69", x"5cb5834a", "000", '0'),
    (x"6c9abf4c", x"9872bac5", "000", '0'),
    (x"5181797a", x"5181797a", "000", '1'),
    (x"e342ed0d", x"e342ed0d", "000", '1'),
    (x"5cb5834a", x"5cb5834a", "000", '1'),
    (x"9872bac5", x"9872bac5", "000", '1'),
    -- BNE (Branch if in1 != in2)
    (x"63aaf6fc", x"63aaf6fc", "001", '0'),
    (x"e199b9e5", x"e199b9e5", "001", '0'),
    (x"7b5dcdb1", x"7b5dcdb1", "001", '0'),
    (x"e9135c81", x"e9135c81", "001", '0'),
    (x"6113e80f", x"63aaf6fc", "001", '1'),
    (x"fe2278fa", x"e199b9e5", "001", '1'),
    (x"cfd9066a", x"7b5dcdb1", "001", '1'),
    (x"13e8ad44", x"e9135c81", "001", '1'),
    -- BLT (Branch if in1 < in2) signed
    (x"6f32107e", x"a014b2b7", "100", '0'),
    (x"ce3d005a", x"a934320d", "100", '0'),
    (x"1c9e6e4b", x"8379780e", "100", '0'),
    (x"22574d2e", x"b7bcbb18", "100", '0'),
    (x"40b456a1", x"60673148", "100", '1'),
    (x"ddbe4e1e", x"476e28d3", "100", '1'),
    (x"40131dd1", x"490821dd", "100", '1'),
    (x"9ff9fda4", x"2d79c240", "100", '1'),
    (x"2d79c240", x"2d79c240", "100", '0'),
    -- BGE (Branch if in1 >= in2) signed
    (x"6f32107e", x"a014b2b7", "101", '1'),
    (x"ce3d005a", x"a934320d", "101", '1'),
    (x"1c9e6e4b", x"8379780e", "101", '1'),
    (x"22574d2e", x"b7bcbb18", "101", '1'),
    (x"40b456a1", x"60673148", "101", '0'),
    (x"ddbe4e1e", x"476e28d3", "101", '0'),
    (x"40131dd1", x"490821dd", "101", '0'),
    (x"9ff9fda4", x"2d79c240", "101", '0'),
    (x"d8e1a84d", x"d8e1a84d", "101", '1'),
    (x"366d3002", x"366d3002", "101", '1'),
    (x"8d7a0b26", x"8d7a0b26", "101", '1'),
    (x"b1b31639", x"b1b31639", "101", '1'),
    -- BLTU (Branch if in1 < in2) unsigned
    (x"dc08c659", x"84b842a0", "110", '0'),
    (x"b6aa811f", x"7939a562", "110", '0'),
    (x"5003ab69", x"15eb9a0d", "110", '0'),
    (x"e159e33e", x"ad295fa5", "110", '0'),
    (x"41471cb6", x"ed284ce4", "110", '1'),
    (x"1e7bc7d7", x"c1a83745", "110", '1'),
    (x"1ae90d62", x"4ef8632b", "110", '1'),
    (x"e07d5499", x"faca7fbf", "110", '1'),
    (x"e07d5499", x"e07d5499", "110", '0'),
    -- BGEU (Branch if in1 >= in2) unsigned
    (x"ab168eea", x"5903c62e", "111", '1'),
    (x"b520861e", x"8096a222", "111", '1'),
    (x"a75bbbe1", x"6068adbf", "111", '1'),
    (x"f0a274cd", x"62ae66f6", "111", '1'),
    (x"a2a520a8", x"e2b51ddc", "111", '0'),
    (x"5ce1915c", x"c50d5cae", "111", '0'),
    (x"6459fee1", x"6e78f651", "111", '0'),
    (x"ba89cdf5", x"fe367c35", "111", '0'),
    (x"ef3c736c", x"ef3c736c", "111", '1'),
    (x"aefaa4e4", x"aefaa4e4", "111", '1'),
    (x"0ab6d2aa", x"0ab6d2aa", "111", '1'),
    (x"f06babfd", x"f06babfd", "111", '1')
  );

  
  -- converts logic vector to hex string
  function to_hstring (SLV : std_logic_vector) return string is
    variable L : LINE;
  begin
    hwrite(L,SLV);
    return L.all;
  end function to_hstring;

  function to_hstring (SLV : std_logic) return string is
    variable L : LINE;
  begin
    write(L,SLV);
    return L.all;
  end function to_hstring;


  component branch_logic is
      port (
        i_clk     : in  std_logic;
        i_ce      : in  std_logic;
        i_in1     : in  std_logic_vector(31 downto 0);
        i_in2     : in  std_logic_vector(31 downto 0);
        i_func    : in  std_logic_vector(2  downto 0);
        o_branch  : out std_logic
      );
    end component branch_logic;

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

    for i in patterns'range loop
      r_ce    <= '1';
      r_in1   <= patterns(i).in1;
      r_in2   <= patterns(i).in2;
      r_func  <= patterns(i).func;
      wait until rising_edge(r_clk);
      r_ce    <= '0';
      wait until rising_edge(r_clk);
      assert (w_branch = patterns(i).branch) report
        "Failed test " & integer'image(i) & ": " &
        "IN1 = " & to_hstring(patterns(i).in1) & " " &
        "IN2 = " & to_hstring(patterns(i).in2) & " " &
        "FUN = " & to_hstring(patterns(i).func) & " " &
        "RES = " & to_hstring(w_branch)
        severity failure;
    end loop;

    -- End simulation
    finish;

  end process p_sim;


  dut : branch_logic
    port map (
      i_clk     => r_clk,
      i_ce      => r_ce,
      i_in1     => r_in1,
      i_in2     => r_in2,
      i_func    => r_func,
      o_branch  => w_branch
    );

end architecture behave;