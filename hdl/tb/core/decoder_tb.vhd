-- *********************************************************************
-- File: decoder_tb.vhd
--
-- Control Logic Testbench
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all; 
use std.env.finish;


entity decoder_tb is
end entity;


architecture behave of decoder_tb is

  constant CLK_P : time := 10 ns;

  signal r_clk          : std_logic := '0';
  signal r_ce           : std_logic;
  signal r_opcode       : std_logic_vector(31 downto 0);
  signal w_rs1          : std_logic_vector( 4 downto 0);
  signal w_rs2          : std_logic_vector( 4 downto 0);
  signal w_rd           : std_logic_vector( 4 downto 0);
  signal w_reg_mux      : std_logic_vector( 2 downto 0);
  signal w_reg_wb       : std_logic;
  signal w_imm          : std_logic_vector(31 downto 0);
  signal w_alu_in1_mux  : std_logic;
  signal w_alu_in2_mux  : std_logic;
  signal w_alu_func     : std_logic_vector(4 downto 0);
  signal w_branch_func  : std_logic_vector(2 downto 0);
  signal w_branch       : std_logic;
  signal w_jump         : std_logic;
  signal w_mem_func     : std_logic_vector(2 downto 0);
  signal w_load         : std_logic;
  signal w_store        : std_logic;


  -- Test patters to apply
  type pattern_type is record
    opcode      : std_logic_vector(31 downto 0);
    rs1         : std_logic_vector(4 downto 0);
    rs2         : std_logic_vector(4  downto 0);
    rd          : std_logic_vector(4 downto 0);
    reg_mux     : std_logic_vector(2 downto 0);
    reg_wb      : std_logic;
    imm         : std_logic_vector(31 downto 0);
    alu_in1_mux : std_logic;
    alu_in2_mux : std_logic;
    alu_func    : std_logic_vector(4 downto 0);
    branch_func : std_logic_vector(2 downto 0);
    branch      : std_logic;
    jump        : std_logic;
    mem_func    : std_logic_vector(2 downto 0);
    load        : std_logic;
    store       : std_logic;
  end record;
  type pattern_array is array (natural range <>) of pattern_type;
  constant patterns : pattern_array := (
    (x"000000b7", "-----", "-----", "00001", "001", '1', x"00000000", '-', '1', "1----", "---", '0', '0', "---", '0', '0'),  -- LUI
    (x"00001137", "-----", "-----", "00010", "001", '1', x"00001000", '-', '1', "1----", "---", '0', '0', "---", '0', '0'),
    (x"80000237", "-----", "-----", "00100", "001", '1', x"80000000", '-', '1', "1----", "---", '0', '0', "---", '0', '0'),
    (x"0aa55437", "-----", "-----", "01000", "001", '1', x"0aa55000", '-', '1', "1----", "---", '0', '0', "---", '0', '0'),
    (x"12345837", "-----", "-----", "10000", "001", '1', x"12345000", '-', '1', "1----", "---", '0', '0', "---", '0', '0'),
    (x"ffffffb7", "-----", "-----", "11111", "001", '1', x"fffff000", '-', '1', "1----", "---", '0', '0', "---", '0', '0'),

    (x"00000097", "-----", "-----", "00001", "001", '1', x"00000000", '1', '1', "00000", "---", '0', '0', "---", '0', '0'),  -- AUIPC
    (x"00001117", "-----", "-----", "00010", "001", '1', x"00001000", '1', '1', "00000", "---", '0', '0', "---", '0', '0'),
    (x"80000217", "-----", "-----", "00100", "001", '1', x"80000000", '1', '1', "00000", "---", '0', '0', "---", '0', '0'),
    (x"0aa55417", "-----", "-----", "01000", "001", '1', x"0aa55000", '1', '1', "00000", "---", '0', '0', "---", '0', '0'),
    (x"12345817", "-----", "-----", "10000", "001", '1', x"12345000", '1', '1', "00000", "---", '0', '0', "---", '0', '0'),
    (x"ffffff97", "-----", "-----", "11111", "001", '1', x"fffff000", '1', '1', "00000", "---", '0', '0', "---", '0', '0'),

    (x"000001ef", "-----", "-----", "00011", "100", '1', x"00000000", '1', '1', "00000", "---", '0', '1', "---", '0', '0'),  -- JAL
    (x"002002ef", "-----", "-----", "00101", "100", '1', x"00000002", '1', '1', "00000", "---", '0', '1', "---", '0', '0'),
    (x"fffff4ef", "-----", "-----", "01001", "100", '1', x"fffffffe", '1', '1', "00000", "---", '0', '1', "---", '0', '0'),
    (x"0040056f", "-----", "-----", "01010", "100", '1', x"00000004", '1', '1', "00000", "---", '0', '1', "---", '0', '0'),
    (x"ffdff7ef", "-----", "-----", "01111", "100", '1', x"fffffffc", '1', '1', "00000", "---", '0', '1', "---", '0', '0'),
    (x"7ffff8ef", "-----", "-----", "10001", "100", '1', x"000ffffe", '1', '1', "00000", "---", '0', '1', "---", '0', '0'),
    (x"80000b6f", "-----", "-----", "10110", "100", '1', x"fff00000", '1', '1', "00000", "---", '0', '1', "---", '0', '0'),

    (x"00000067", "00000", "-----", "00000", "100", '1', x"00000000", '0', '1', "00000", "---", '0', '1', "---", '0', '0'),  -- JALR
    (x"00408367", "00001", "-----", "00110", "100", '1', x"00000004", '0', '1', "00000", "---", '0', '1', "---", '0', '0'),
    (x"ffc103e7", "00010", "-----", "00111", "100", '1', x"fffffffc", '0', '1', "00000", "---", '0', '1', "---", '0', '0'),
    (x"3e8205e7", "00100", "-----", "01011", "100", '1', x"000003e8", '0', '1', "00000", "---", '0', '1', "---", '0', '0'),
    (x"c18786e7", "01111", "-----", "01101", "100", '1', x"fffffc18", '0', '1', "00000", "---", '0', '1', "---", '0', '0'),
    (x"7ff88e67", "10001", "-----", "11100", "100", '1', x"000007ff", '0', '1', "00000", "---", '0', '1', "---", '0', '0'),
    (x"801f8ee7", "11111", "-----", "11101", "100", '1', x"fffff801", '0', '1', "00000", "---", '0', '1', "---", '0', '0'),

    (x"000f8063", "11111", "00000", "-----", "---", '0', x"00000000", '1', '1', "00000", "000", '1', '0', "---", '0', '0'),  -- BEQ
    (x"00180163", "10000", "00001", "-----", "---", '0', x"00000002", '1', '1', "00000", "000", '1', '0', "---", '0', '0'),
    (x"fe240ee3", "01000", "00010", "-----", "---", '0', x"fffffffc", '1', '1', "00000", "000", '1', '0', "---", '0', '0'),
    (x"004200e3", "00100", "00100", "-----", "---", '0', x"00000800", '1', '1', "00000", "000", '1', '0', "---", '0', '0'),
    (x"00810f63", "00010", "01000", "-----", "---", '0', x"0000001e", '1', '1', "00000", "000", '1', '0', "---", '0', '0'),
    (x"81008063", "00001", "10000", "-----", "---", '0', x"fffff000", '1', '1', "00000", "000", '1', '0', "---", '0', '0'),
    (x"7ff00063", "00000", "11111", "-----", "---", '0', x"000007e0", '1', '1', "00000", "000", '1', '0', "---", '0', '0'),
    (x"00001a63", "00000", "00000", "-----", "---", '0', x"00000014", '1', '1', "00000", "001", '1', '0', "---", '0', '0'),  -- BNE
    (x"00004863", "00000", "00000", "-----", "---", '0', x"00000010", '1', '1', "00000", "100", '1', '0', "---", '0', '0'),  -- BLT
    (x"00005663", "00000", "00000", "-----", "---", '0', x"0000000c", '1', '1', "00000", "101", '1', '0', "---", '0', '0'),  -- BGE
    (x"fce7d6e3", "01111", "01110", "-----", "---", '0', x"ffffffcc", '1', '1', "00000", "101", '1', '0', "---", '0', '0'),  -- BGE
    (x"00006463", "00000", "00000", "-----", "---", '0', x"00000008", '1', '1', "00000", "110", '1', '0', "---", '0', '0'),  -- BLTU
    (x"00007263", "00000", "00000", "-----", "---", '0', x"00000004", '1', '1', "00000", "111", '1', '0', "---", '0', '0'),  -- BGEU

    (x"00080083", "10000", "-----", "00001", "010", '1', x"00000000", '0', '1', "00000", "---", '0', '0', "000", '1', '0'),  -- LB
    (x"00441103", "01000", "-----", "00010", "010", '1', x"00000004", '0', '1', "00000", "---", '0', '0', "001", '1', '0'),  -- LH
    (x"ffc22203", "00100", "-----", "00100", "010", '1', x"fffffffc", '0', '1', "00000", "---", '0', '0', "010", '1', '0'),  -- LW
    (x"7ff14403", "00010", "-----", "01000", "010", '1', x"000007ff", '0', '1', "00000", "---", '0', '0', "100", '1', '0'),  -- LBU
    (x"8010d803", "00001", "-----", "10000", "010", '1', x"fffff801", '0', '1', "00000", "---", '0', '0', "101", '1', '0'),  -- LHU

    (x"00b38023", "00111", "01011", "-----", "---", '0', x"00000000", '0', '1', "00000", "---", '0', '0', "000", '0', '1'),  -- SB
    (x"01761223", "01100", "10111", "-----", "---", '0', x"00000004", '0', '1', "00000", "---", '0', '0', "001", '0', '1'),  -- SH
    (x"ff5f2e23", "11110", "10101", "-----", "---", '0', x"fffffffc", '0', '1', "00000", "---", '0', '0', "010", '0', '1'),  -- SW

    (x"00008013", "00001", "-----", "00000", "001", '1', x"00000000", '0', '1', "00000", "---", '0', '0', "---", '0', '0'),  -- ADDI
    (x"0000a013", "00001", "-----", "00000", "001", '1', x"00000000", '0', '1', "00010", "---", '0', '0', "---", '0', '0'),  -- SLTI
    (x"0000b013", "00001", "-----", "00000", "001", '1', x"00000000", '0', '1', "00011", "---", '0', '0', "---", '0', '0'),  -- SLTIU
    (x"0000c013", "00001", "-----", "00000", "001", '1', x"00000000", '0', '1', "00100", "---", '0', '0', "---", '0', '0'),  -- XORI
    (x"0000e013", "00001", "-----", "00000", "001", '1', x"00000000", '0', '1', "00110", "---", '0', '0', "---", '0', '0'),  -- ORI
    (x"0000f013", "00001", "-----", "00000", "001", '1', x"00000000", '0', '1', "00111", "---", '0', '0', "---", '0', '0'),  -- ANDI

    (x"00109013", "00001", "-----", "00000", "001", '1', x"00000001", '0', '1', "00001", "---", '0', '0', "---", '0', '0'),  -- SLLI
    (x"0100d013", "00001", "-----", "00000", "001", '1', x"00000010", '0', '1', "00101", "---", '0', '0', "---", '0', '0'),  -- SRLI
    (x"41f0d013", "00001", "-----", "00000", "001", '1', x"0000041f", '0', '1', "01101", "---", '0', '0', "---", '0', '0'),  -- SRAI

    (x"00208033", "00001", "00010", "00000", "001", '1', x"--------", '0', '0', "00000", "---", '0', '0', "---", '0', '0'),  -- ADD
    (x"40208033", "00001", "00010", "00000", "001", '1', x"--------", '0', '0', "01000", "---", '0', '0', "---", '0', '0'),  -- SUB
    (x"00209033", "00001", "00010", "00000", "001", '1', x"--------", '0', '0', "00001", "---", '0', '0', "---", '0', '0'),  -- SLL
    (x"0020a033", "00001", "00010", "00000", "001", '1', x"--------", '0', '0', "00010", "---", '0', '0', "---", '0', '0'),  -- SLT
    (x"0020b033", "00001", "00010", "00000", "001", '1', x"--------", '0', '0', "00011", "---", '0', '0', "---", '0', '0'),  -- SLTU
    (x"0020c033", "00001", "00010", "00000", "001", '1', x"--------", '0', '0', "00100", "---", '0', '0', "---", '0', '0'),  -- XOR
    (x"0020d033", "00001", "00010", "00000", "001", '1', x"--------", '0', '0', "00101", "---", '0', '0', "---", '0', '0'),  -- SRL
    (x"4020d033", "00001", "00010", "00000", "001", '1', x"--------", '0', '0', "01101", "---", '0', '0', "---", '0', '0'),  -- SRA
    (x"0020e033", "00001", "00010", "00000", "001", '1', x"--------", '0', '0', "00110", "---", '0', '0', "---", '0', '0'),  -- OR
    (x"0020f033", "00001", "00010", "00000", "001", '1', x"--------", '0', '0', "00111", "---", '0', '0', "---", '0', '0')   -- AND
  );


  -- returns false if inputs are different, true if one ore both are don't care
  function compare (in1, in2 : in std_logic) return boolean is
  begin
    return in1 = in2 or in1 = '-' or in2 = '-';
  end function compare;

  -- returns false if inputs are different, true if one ore both are don't care
  function compare (in1, in2 : in std_logic_vector) return boolean is
  begin
    for i in in1'range loop
      if(compare(in1(i), in2(i)) = false) then
        return false;
      end if;
    end loop;
    return true;
  end function compare;

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


  component decoder is
    port (
      i_clk         : in  std_logic;
      i_ce          : in  std_logic;
      i_opcode      : in  std_logic_vector(31 downto 0);
      o_rs1         : out std_logic_vector( 4 downto 0);
      o_rs2         : out std_logic_vector( 4 downto 0);
      o_rd          : out std_logic_vector( 4 downto 0);
      o_reg_mux     : out std_logic_vector( 2 downto 0);
      o_reg_wb      : out std_logic;
      o_imm         : out std_logic_vector(31 downto 0);
      o_alu_in1_mux : out std_logic;
      o_alu_in2_mux : out std_logic;
      o_alu_func    : out std_logic_vector(4 downto 0);
      o_branch_func : out std_logic_vector(2 downto 0);
      o_branch      : out std_logic;
      o_jump        : out std_logic;
      o_mem_func    : out std_logic_vector(2 downto 0);
      o_load        : out std_logic;
      o_store       : out std_logic
    );
  end component decoder;

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
      r_opcode <= patterns(i).opcode;
      wait until rising_edge(r_clk);
      r_ce    <= '0';
      wait until rising_edge(r_clk);
      assert compare(w_rs1          , patterns(i).rs1        ) report "Failed test " & integer'image(i) & " RS1 = "         & to_hstring(w_rs1        ) & " EXPECTED: " & to_hstring(patterns(i).rs1        ) severity failure;
      assert compare(w_rs2          , patterns(i).rs2        ) report "Failed test " & integer'image(i) & " RS2 = "         & to_hstring(w_rs2        ) & " EXPECTED: " & to_hstring(patterns(i).rs2        ) severity failure;
      assert compare(w_rd           , patterns(i).rd         ) report "Failed test " & integer'image(i) & " RD = "          & to_hstring(w_rd         ) & " EXPECTED: " & to_hstring(patterns(i).rd         ) severity failure;
      assert compare(w_reg_mux      , patterns(i).reg_mux    ) report "Failed test " & integer'image(i) & " REG_MUX = "     & to_hstring(w_reg_mux    ) & " EXPECTED: " & to_hstring(patterns(i).reg_mux    ) severity failure;
      assert compare(w_reg_wb       , patterns(i).reg_wb     ) report "Failed test " & integer'image(i) & " REG_WB = "      & to_hstring(w_reg_wb     ) & " EXPECTED: " & to_hstring(patterns(i).reg_wb     ) severity failure;
      assert compare(w_imm          , patterns(i).imm        ) report "Failed test " & integer'image(i) & " IMM = "         & to_hstring(w_imm        ) & " EXPECTED: " & to_hstring(patterns(i).imm        ) severity failure;
      assert compare(w_alu_in1_mux  , patterns(i).alu_in1_mux) report "Failed test " & integer'image(i) & " ALU_IN1_MUX = " & to_hstring(w_alu_in1_mux) & " EXPECTED: " & to_hstring(patterns(i).alu_in1_mux) severity failure;
      assert compare(w_alu_in2_mux  , patterns(i).alu_in2_mux) report "Failed test " & integer'image(i) & " ALU_IN2_MUX = " & to_hstring(w_alu_in2_mux) & " EXPECTED: " & to_hstring(patterns(i).alu_in2_mux) severity failure;
      assert compare(w_alu_func     , patterns(i).alu_func   ) report "Failed test " & integer'image(i) & " ALU_FUNC = "    & to_hstring(w_alu_func   ) & " EXPECTED: " & to_hstring(patterns(i).alu_func   ) severity failure;
      assert compare(w_branch_func  , patterns(i).branch_func) report "Failed test " & integer'image(i) & " BRANCH_FUNC = " & to_hstring(w_branch_func) & " EXPECTED: " & to_hstring(patterns(i).branch_func) severity failure;
      assert compare(w_branch       , patterns(i).branch     ) report "Failed test " & integer'image(i) & " BRANCH = "      & to_hstring(w_branch     ) & " EXPECTED: " & to_hstring(patterns(i).branch     ) severity failure;
      assert compare(w_jump         , patterns(i).jump       ) report "Failed test " & integer'image(i) & " JUMP = "        & to_hstring(w_jump       ) & " EXPECTED: " & to_hstring(patterns(i).jump       ) severity failure;
      assert compare(w_mem_func     , patterns(i).mem_func   ) report "Failed test " & integer'image(i) & " MEM_FUNC = "    & to_hstring(w_mem_func   ) & " EXPECTED: " & to_hstring(patterns(i).mem_func   ) severity failure;
      assert compare(w_load         , patterns(i).load       ) report "Failed test " & integer'image(i) & " LOAD = "        & to_hstring(w_load       ) & " EXPECTED: " & to_hstring(patterns(i).load       ) severity failure;
      assert compare(w_store        , patterns(i).store      ) report "Failed test " & integer'image(i) & " STORE = "       & to_hstring(w_store      ) & " EXPECTED: " & to_hstring(patterns(i).store      ) severity failure;
    end loop;

    -- End simulation
    finish;

  end process p_sim;


  dut : decoder
    port map (
        i_clk         => r_clk,
        i_ce          => r_ce,
        i_opcode      => r_opcode,
        o_rs1         => w_rs1,
        o_rs2         => w_rs2,
        o_rd          => w_rd,
        o_reg_mux     => w_reg_mux,
        o_reg_wb      => w_reg_wb,
        o_imm         => w_imm,
        o_alu_in1_mux => w_alu_in1_mux,
        o_alu_in2_mux => w_alu_in2_mux,
        o_alu_func    => w_alu_func,
        o_branch_func => w_branch_func,
        o_branch      => w_branch,
        o_jump        => w_jump,
        o_mem_func    => w_mem_func,
        o_load        => w_load,
        o_store       => w_store
    );

end architecture behave;