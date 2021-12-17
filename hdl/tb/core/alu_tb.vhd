-- *********************************************************************
-- File: alu_tb.vhd
--
-- Arithmetic and Logic Unit. Testbench
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all; 
use std.env.finish;


entity alu_tb is
end entity;


architecture behave of alu_tb is

  constant CLK_P : time := 10 ns;

  signal r_clk   : std_logic                      := '0';
  signal r_ce    : std_logic                      := '0';
  signal r_in1   : std_logic_vector(31 downto 0)  := (others=>'0');
  signal r_in2   : std_logic_vector(31 downto 0)  := (others=>'0');
  signal r_func  : std_logic_vector(4  downto 0)  := (others=>'0');
  signal w_res   : std_logic_vector(31 downto 0);

  -- Test patters to apply
  type pattern_type is record
    in1   : std_logic_vector(31 downto 0);
    in2   : std_logic_vector(31 downto 0);
    func  : std_logic_vector(4  downto 0);
    res   : std_logic_vector(31 downto 0);
  end record;
  type pattern_array is array (natural range <>) of pattern_type;
  constant patterns : pattern_array := (
    -- Bypass (res = i2)
    (x"98228b29", x"230207be", "10000", x"230207be"),
    (x"12479154", x"0626edb3", "10001", x"0626edb3"),
    (x"8092b3cc", x"ba312fdb", "10010", x"ba312fdb"),
    (x"5e2a08a5", x"f74cb515", "10011", x"f74cb515"),
    (x"fd26e713", x"22b64be6", "10100", x"22b64be6"),
    (x"53ef0465", x"8c35a11b", "10101", x"8c35a11b"),
    (x"d6728320", x"2401a7c3", "10110", x"2401a7c3"),
    (x"92ab75d7", x"fc583bb7", "10111", x"fc583bb7"),
    (x"43ef47ed", x"723e1ef1", "11000", x"723e1ef1"),
    (x"ce586051", x"c965369c", "11001", x"c965369c"),
    (x"7bf6750f", x"3e635fc2", "11010", x"3e635fc2"),
    (x"e1cdb606", x"692269fd", "11011", x"692269fd"),
    (x"e2b6790b", x"c3216574", "11100", x"c3216574"),
    (x"d6712f47", x"8befeb9c", "11101", x"8befeb9c"),
    (x"ce11c12b", x"76ff6a72", "11110", x"76ff6a72"),
    (x"6b4ea506", x"170b3765", "11111", x"170b3765"),
    -- ADD (res = in1 + in2)
    (x"37122f7f", x"f374316c", "00000", x"2A8660EB"),
    (x"1ff3a56b", x"50bb401b", "00000", x"70AEE586"),
    (x"b635ff17", x"e9277ad2", "00000", x"9F5D79E9"),
    (x"ce5de5c1", x"c754eab6", "00000", x"95B2D077"),
    -- SUB (res = in1 - in2)
    (x"0cc70c4a", x"9daca4e6", "01000", x"6f1a6764"),
    (x"f922cd6f", x"6a534d93", "01000", x"8ECF7FDC"),
    (x"c9143cbc", x"09dcea3b", "01000", x"BF375281"),
    (x"cc6e5047", x"8528f93a", "01000", x"4745570D"),
    -- SSL (res = in1 << in2)
    (x"8404e7b2", x"00000000", "00001", x"8404e7b2"),
    (x"2bec2830", x"00000004", "00001", x"BEC28300"),
    (x"486de7b3", x"0000000f", "00001", x"F3D98000"),
    (x"7265a7c4", x"0000001f", "00001", x"00000000"),
    -- SLT (res = (in1 < in2) ? 1 : 0) signed
    (x"1bf4995f", x"d8e1a84d", "00010", x"00000000"),
    (x"366d3002", x"510a86e5", "00010", x"00000001"),
    (x"8d7a0b26", x"7fc682bf", "00010", x"00000001"),
    (x"28a47074", x"b1b31639", "00010", x"00000000"),
    -- SLTU (res = (in1 < in2) ? 1 : 0) unsigned
    (x"d8e1a84d", x"1bf4995f", "00011", x"00000000"),
    (x"366d3002", x"510a86e5", "00011", x"00000001"),
    (x"8d7a0b26", x"7fc682bf", "00011", x"00000000"),
    (x"b1b31639", x"28a47074", "00011", x"00000000"),
    -- XOR (res = in1 xor in2)
    (x"8375dc3c", x"72a71d05", "00100", x"F1D2C139"),
    (x"a091a96c", x"554695ae", "00100", x"F5D73CC2"),
    (x"558bcccf", x"abf2c93a", "00100", x"FE7905F5"),
    (x"1152c059", x"0c8c190c", "00100", x"1DDED955"),
    -- srl (res = in1 >> in2) logical
    (x"8375dc3c", x"00000000", "00101", x"8375dc3c"),
    (x"a091a96c", x"00000004", "00101", x"0A091A96"),
    (x"558bcccf", x"0000000f", "00101", x"0000AB17"),
    (x"1152c059", x"0000001f", "00101", x"00000000"),
    -- sra (res = in1 >> in2) arithmetical
    (x"8375dc3c", x"00000000", "01101", x"8375dc3c"),
    (x"a091a96c", x"00000004", "01101", x"FA091A96"),
    (x"c58bcccf", x"0000000f", "01101", x"FFFF8B17"),
    (x"8152c059", x"0000001f", "01101", x"FFFFFFFF"),
    -- OR (res = in1 or in2)
    (x"f9837e37", x"7cc93e8e", "00110", x"FDCB7EBF"),
    (x"fd2f5e2b", x"222b2562", "00110", x"FF2F7F6B"),
    (x"a2852dc8", x"417df935", "00110", x"E3FDFDFD"),
    (x"84cd910f", x"d06a09d8", "00110", x"D4EF99DF"),
    -- AND (res = in1 and in2)
    (x"b8167396", x"adf5bb1b", "00111", x"A8143312"),
    (x"bc6faace", x"45452fdc", "00111", x"04452ACC"),
    (x"6ba19696", x"f53e86f6", "00111", x"61208696"),
    (x"67196e26", x"bab05c1f", "00111", x"22104C06")
  );


  function to_hstring (SLV : std_logic_vector) return string is
    variable L : LINE;
  begin
    hwrite(L,SLV);
    return L.all;
  end function to_hstring;


  component alu is
      port (
        i_clk   : in  std_logic;
        i_ce    : in  std_logic;
        i_in1   : in  std_logic_vector(31 downto 0);
        i_in2   : in  std_logic_vector(31 downto 0);
        i_func  : in  std_logic_vector(4  downto 0);
        o_res   : out std_logic_vector(31 downto 0)
      );
    end component alu;

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
      assert (w_res = patterns(i).res) report
        "Failed test " & integer'image(i) & ": " &
        "IN1 = " & to_hstring(patterns(i).in1) & " " &
        "IN2 = " & to_hstring(patterns(i).in2) & " " &
        "FUN = " & to_hstring(patterns(i).func) & " " &
        "RES = " & to_hstring(w_res)
        severity failure;
    end loop;

    -- End simulation
    finish;

  end process p_sim;


  dut : alu
    port map (
      i_clk   => r_clk,
      i_ce    => r_ce,
      i_in1   => r_in1,
      i_in2   => r_in2,
      i_func  => r_func,
      o_res   => w_res
    );

end architecture behave;