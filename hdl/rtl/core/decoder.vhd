-- *********************************************************************
-- File: decoder.vhd
--
-- CPU Instruction Decoder
--
-- Generic:
--
-- Port:
--  i_clk:          clock input
--  i_ce:           clock enable active HIGH
--  i_opcode:       instruction to decode
--  o_rs1:          source register 1
--  o_rs2:          source register 2
--  o_rd:           destination register
--  o_reg_mux:      register input multiplexer
--  o_reg_wb:       enable register write back
--  o_imm:          immediate value
--  o_alu_in1_mux:  alu input 1 multiplexer
--  o_alu_in2_mux:  alu input 2 multiplexer
--  o_alu_func:     alu function
--  o_branch_func:  branch condition
--  o_branch:       this is a branch instruction
--  o_jump:         this is a jump instruction
--  o_mem_func:     data memory function
--  o_load:         this is a load instruction
--  o_store:        this is a store instruction
--
-- *********************************************************************


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity decoder is
  port (
    i_clk         : in  std_logic;
    i_ce          : in  std_logic;
    i_opcode      : in  std_logic_vector(31 downto 0);
    o_rs1         : out std_logic_vector( 4 downto 0);
    o_rs2         : out std_logic_vector( 4 downto 0);
    o_rd          : out std_logic_vector( 4 downto 0);
    o_reg_mux     : out std_logic_vector( 1 downto 0);
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
end entity decoder;


architecture behave of decoder is

  type e_type is (ALU_REG, ALU_IMM, LOAD, JALR, STORE, BRANCH, LUI, AUIPC, JAL, ILLEGAL);
  signal w_ins_type : e_type;


  signal w_rs1         : std_logic_vector( 4 downto 0);
  signal w_rs2         : std_logic_vector( 4 downto 0);
  signal w_rd          : std_logic_vector( 4 downto 0);
  signal w_reg_mux     : std_logic_vector( 1 downto 0);
  signal w_reg_wb      : std_logic;
  signal w_imm         : std_logic_vector(31 downto 0);
  signal w_alu_in1_mux : std_logic;
  signal w_alu_in2_mux : std_logic;
  signal w_alu_func    : std_logic_vector(4 downto 0);
  signal w_branch_func : std_logic_vector(2 downto 0);
  signal w_branch      : std_logic;
  signal w_jump        : std_logic;
  signal w_mem_func    : std_logic_vector(2 downto 0);
  signal w_load        : std_logic;
  signal w_store       : std_logic;

begin

  -- Decode instruction type
  with i_opcode(6 downto 2) select
    w_ins_type <= ALU_REG when "01100",
                  ALU_IMM when "00100",
                  LOAD    when "00000",
                  JALR    when "11001",
                  STORE   when "01000",
                  BRANCH  when "11000",
                  LUI     when "01101",
                  AUIPC   when "00101",
                  JAL     when "11011",
                  ILLEGAL when others;

  -- Signals straight from the opcode
  w_rs1         <= i_opcode(19 downto 15);
  w_rs2         <= i_opcode(24 downto 20);
  w_rd          <= i_opcode(11 downto 7);
  w_branch_func <= i_opcode(14 downto 12);

  -- ALU control signals
  w_alu_func(3)           <= '1' when (i_opcode(30) = '1' and (w_ins_type = ALU_REG or i_opcode(14 downto 12) = "101")) else '0';
  w_alu_func(2 downto 0)  <= i_opcode(14 downto 12) when (w_ins_type = ALU_REG or w_ins_type = ALU_IMM) else "000";

  -- Control signals
  w_reg_mux     <= "01" when (w_ins_type = LOAD) else
                   "10" when (w_ins_type = JAL)  else
                   "10" when (w_ins_type = JALR) else
                   "00";
  w_reg_wb      <= '0'  when (w_ins_type = STORE or w_ins_type = BRANCH)  else '1';
  w_alu_in1_mux <= '1'  when (w_ins_type = AUIPC or w_ins_type = JAL or w_ins_type = BRANCH) else '0';
  w_alu_in2_mux <= '0'  when (w_ins_type = ALU_REG) else '1';
  w_alu_func(4) <= '1'  when (w_ins_type = LUI)     else '0';
  w_branch      <= '1'  when (w_ins_type = BRANCH)  else '0';
  w_jump        <= '1'  when (w_ins_type = JALR or w_ins_type = JAL) else '0';
  w_load        <= '1'  when (w_ins_type = LOAD)  else '0';
  w_store       <= '1'  when (w_ins_type = STORE) else '0';

  w_mem_func <= i_opcode(14 downto 12);

  -- Decode immediate
  p_imm : process (i_opcode, w_ins_type)
  begin
    if (w_ins_type = JALR or w_ins_type = LOAD or w_ins_type = ALU_IMM) then
      -- I-TYPE
      w_imm(11 downto  0) <= i_opcode(31 downto 20);
      w_imm(31 downto 12) <= (others=>i_opcode(31));
    elsif (w_ins_type = STORE) then
      -- S-TYPE
      w_imm(11 downto  0) <= i_opcode(31 downto 25) & i_opcode(11 downto 7);
      w_imm(31 downto 12) <= (others=>i_opcode(31));
    elsif (w_ins_type = BRANCH) then
      -- B-TYPE
      w_imm(11 downto  0) <= i_opcode(7) & i_opcode(30 downto 25) & i_opcode(11 downto 8) & '0';
      w_imm(31 downto 12) <= (others=>i_opcode(31));
    elsif (w_ins_type = LUI or w_ins_type = AUIPC) then
      -- U-TYPE
      w_imm(11 downto  0) <= (others=>'0');
      w_imm(31 downto 12) <= i_opcode(31 downto 12);
    else
      -- J-TYPE
      w_imm(19 downto  0) <= i_opcode(19 downto 12) & i_opcode(20) & i_opcode(30 downto 21) & '0';
      w_imm(31 downto 20) <= (others=>i_opcode(31));
    end if;
  end process p_imm;
  

  -- Update outputs on i_clk rising edge when the decoder is enabled
  p_out : process (i_clk)
  begin
    if (rising_edge(i_clk)) then
      if (i_ce = '1') then
        o_rs1         <= w_rs1;        
        o_rs2         <= w_rs2;        
        o_rd          <= w_rd;         
        o_reg_mux     <= w_reg_mux;    
        o_reg_wb      <= w_reg_wb;     
        o_imm         <= w_imm;        
        o_alu_in1_mux <= w_alu_in1_mux;
        o_alu_in2_mux <= w_alu_in2_mux;
        o_alu_func    <= w_alu_func;   
        o_branch_func <= w_branch_func;
        o_branch      <= w_branch;     
        o_jump        <= w_jump;       
        o_mem_func    <= w_mem_func;
        o_load        <= w_load;       
        o_store       <= w_store;      
      end if;
    end if;
  end process p_out;

end architecture behave;