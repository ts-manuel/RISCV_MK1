-- *********************************************************************
-- File: riscv_mk1.vhd
--
-- RISC-V MK1 CPU Core
--
--
-- Debug vector:
--  o_debug_vector(0): w_phase_fetch
--  o_debug_vector(1): w_phase_decode
--  o_debug_vector(2): w_phase_execute
--  o_debug_vector(3): w_phase_memory
--  o_debug_vector(4): w_phase_write_back
--
--
-- Generic:
--
-- Port:
--  i_clk:             clock input
--  i_rst:             reset active HIGH
--  o_av_read:         Avalon memory bus
--  o_av_write:        Avalon memory bus
--  o_av_byte_enable:  Avalon memory bus
--  o_av_addr:         Avalon memory bus
--  o_av_writedata:    Avalon memory bus
--  i_av_waitrequest:  Avalon memory bus
--  i_av_readdata:     Avalon memory bus
--  o_debug_vector:    Debug signals
--
-- *********************************************************************


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity riscv_mk1 is
  port (
    i_clk             : in  std_logic;
    i_rst             : in  std_logic;
    -- Avalon memory interface
    o_av_addr         : out std_logic_vector(29 downto 0);
    o_av_byteenable   : out std_logic_vector(3 downto 0);
    o_av_read         : out std_logic;
    o_av_write        : out std_logic;
    i_av_waitrequest  : in  std_logic;
    o_av_writedata    : out std_logic_vector(31 downto 0);
    i_av_readdata     : in  std_logic_vector(31 downto 0);
    -- Debud signals
    o_debug_vector    : out std_logic_vector(31 downto 0);
    o_debug_opcode    : out std_logic_vector(31 downto 0);
    o_debug_pc        : out std_logic_vector(31 downto 0)
  );
end entity riscv_mk1;


architecture behave of riscv_mk1 is

  signal w_fetch_wait       : std_logic;
  signal w_memory_wait      : std_logic;
  signal w_phase_fetch      : std_logic;
  signal w_phase_decode     : std_logic;
  signal w_phase_execute    : std_logic;
  signal w_phase_memory     : std_logic;
  signal w_phase_write_back : std_logic;

  signal w_opcode       : std_logic_vector(31 downto 0);
  signal w_rs1          : std_logic_vector( 4 downto 0);
  signal w_rs2          : std_logic_vector( 4 downto 0);
  signal w_rd           : std_logic_vector( 4 downto 0);
  signal w_reg_mux      : std_logic_vector( 1 downto 0);
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

  signal w_reg_ce   : std_logic;
  signal w_reg_in   : std_logic_vector(31 downto 0);
  signal w_reg_out1 : std_logic_vector(31 downto 0);
  signal w_reg_out2 : std_logic_vector(31 downto 0);

  signal w_alu_in1  : std_logic_vector(31 downto 0);
  signal w_alu_in2  : std_logic_vector(31 downto 0);
  signal w_alu_out  : std_logic_vector(31 downto 0);

  signal w_take_branch  : std_logic;

  signal w_data_out : std_logic_vector(31 downto 0);

  signal w_pc_load  : std_logic;
  signal w_pc_next  : std_logic_vector(31 downto 0);
  signal w_pc       : std_logic_vector(31 downto 0);

  -- Instruction and Data memory intermediate signals
  signal w_data_memory_active   : std_logic;
  signal w_av_inst_read         : std_logic;
  signal w_av_inst_write        : std_logic;
  signal w_av_inst_byteenable   : std_logic_vector(3 downto 0);
  signal w_av_inst_addr         : std_logic_vector(29 downto 0);
  signal w_av_inst_writedata    : std_logic_vector(31 downto 0);
  signal w_av_inst_waitrequest  : std_logic;
  signal w_av_inst_readdata     : std_logic_vector(31 downto 0);
  signal w_av_data_read         : std_logic;
  signal w_av_data_write        : std_logic;
  signal w_av_data_byteenable   : std_logic_vector(3 downto 0);
  signal w_av_data_addr         : std_logic_vector(29 downto 0);
  signal w_av_data_writedata    : std_logic_vector(31 downto 0);
  signal w_av_data_waitrequest  : std_logic;
  signal w_av_data_readdata     : std_logic_vector(31 downto 0);


  component control_unit is
    port (
      i_clk         : in  std_logic;
      i_rst         : in  std_logic;
      i_fetch_wait  : in  std_logic;
      i_memory_wait : in  std_logic;
      o_fetch       : out std_logic;
      o_decode      : out std_logic;
      o_execute     : out std_logic;
      o_memory      : out std_logic;
      o_write_back  : out std_logic
    );
  end component control_unit;

  component decoder is
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
  end component decoder;

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

  component alu is
    port (
      i_clk   : in  std_logic;
      i_ce    : in  std_logic;
      i_in1   : in  std_logic_vector(31 downto 0);
      i_in2   : in  std_logic_vector(31 downto 0);
      i_func  : in  std_logic_vector(4 downto 0);
      o_res   : out std_logic_vector(31 downto 0)
    );
  end component alu;

  component branch_logic is
    port (
      i_clk     : in std_logic;
      i_ce      : in std_logic;
      i_in1     : in std_logic_vector(31 downto 0);
      i_in2     : in std_logic_vector(31 downto 0);
      i_func    : in std_logic_vector(2 downto 0);
      o_branch  : out std_logic
    );
  end component branch_logic;

  component dmem_interface is
    port (
      i_clk             : in  std_logic;
      i_ce              : in  std_logic;
      i_addr            : in  std_logic_vector(31 downto 0);
      i_writedata       : in  std_logic_vector(31 downto 0);
      i_rd              : in  std_logic;
      i_wr              : in  std_logic;
      i_func            : in  std_logic_vector(2 downto 0);
      o_readdata        : out std_logic_vector(31 downto 0);
      o_wait            : out std_logic;
      o_av_addr         : out std_logic_vector(29 downto 0);
      o_av_byteenable   : out std_logic_vector(3 downto 0);
      o_av_read         : out std_logic;
      o_av_write        : out std_logic;
      i_av_waitrequest  : in  std_logic;
      o_av_writedata    : out std_logic_vector(31 downto 0);
      i_av_readdata     : in  std_logic_vector(31 downto 0)
    );
  end component dmem_interface;

  component imem_interface is
    port (
      i_clk             : in  std_logic;
      i_ce              : in  std_logic;
      i_pc              : in  std_logic_vector(31 downto 0);
      o_av_addr         : out std_logic_vector(29 downto 0);
      o_av_byteenable   : out std_logic_vector(3 downto 0);
      o_av_read         : out std_logic;
      o_av_write        : out std_logic;
      i_av_waitrequest  : in  std_logic;
      o_av_writedata    : out std_logic_vector(31 downto 0);
      i_av_readdata     : in  std_logic_vector(31 downto 0);
      o_opcode          : out std_logic_vector(31 downto 0);
      o_wait            : out std_logic
    );
  end component imem_interface;

  component program_counter is
    port (
      i_clk     : in  std_logic;
      i_rst     : in  std_logic;
      i_ce      : in  std_logic;
      i_load    : in  std_logic;
      i_value   : in  std_logic_vector(31 downto 0);
      o_pc      : out std_logic_vector(31 downto 0);
      o_pc_next : out std_logic_vector(31 downto 0)
    );
  end component program_counter;

begin

  -- Register input multiplexer
  w_reg_in <= w_alu_out   when (w_reg_mux = "00") else
              w_data_out  when (w_reg_mux = "01") else
              w_pc_next;

  -- ALU input multiplexers
  w_alu_in1 <= w_reg_out1 when (w_alu_in1_mux = '0') else w_pc;
  w_alu_in2 <= w_reg_out2 when (w_alu_in2_mux = '0') else w_imm;

  -- Combinatorial control signals
  w_reg_ce <= w_phase_write_back and w_reg_wb;
  w_pc_load <= w_jump or (w_branch and w_take_branch);

  -- Multiplexing betwen instruction and data bus
  w_data_memory_active  <= w_av_data_read or w_av_data_write;
  o_av_read             <= w_av_inst_read or w_av_data_read;
  o_av_write            <= w_av_inst_write or w_av_data_write;
  o_av_byteenable       <= w_av_data_byteenable when (w_data_memory_active = '1') else w_av_inst_byteenable;
  o_av_addr             <= w_av_data_addr       when (w_data_memory_active = '1') else w_av_inst_addr;
  o_av_writedata        <= w_av_data_writedata  when (w_data_memory_active = '1') else w_av_inst_writedata;
  w_av_inst_waitrequest <= i_av_waitrequest;
  w_av_data_waitrequest <= i_av_waitrequest;
  w_av_inst_readdata    <= i_av_readdata;
  w_av_data_readdata    <= i_av_readdata;


  -- Debud signals
  o_debug_vector(0)           <= w_phase_fetch;
  o_debug_vector(1)           <= w_phase_decode;
  o_debug_vector(2)           <= w_phase_execute;
  o_debug_vector(3)           <= w_phase_memory;
  o_debug_vector(4)           <= w_phase_write_back;
  o_debug_vector(31 downto 5) <= (others=>'0');

  o_debug_opcode  <= w_opcode;
  o_debug_pc      <= w_pc;


  control_unit0 : control_unit
    port map (
      i_clk         => i_clk,
      i_rst         => i_rst,
      i_fetch_wait  => w_fetch_wait,
      i_memory_wait => w_memory_wait,
      o_fetch       => w_phase_fetch,
      o_decode      => w_phase_decode,
      o_execute     => w_phase_execute,
      o_memory      => w_phase_memory,
      o_write_back  => w_phase_write_back
    );

  decoder0 : decoder
    port map (
      i_clk         => i_clk,
      i_ce          => w_phase_decode,
      i_opcode      => w_opcode,
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

  registers0 : registers
    port map (
      i_clk   => i_clk,
      i_ce    => w_reg_ce,
      i_rs1   => w_rs1,
      i_rs2   => w_rs2,
      i_rd    => w_rd,
      i_value => w_reg_in,
      o_reg1  => w_reg_out1,
      o_reg2  => w_reg_out2
    );

  alu0 : alu
    port map (
      i_clk   => i_clk,
      i_ce    => w_phase_execute,
      i_in1   => w_alu_in1,
      i_in2   => w_alu_in2,
      i_func  => w_alu_func,
      o_res   => w_alu_out
    );

  branch_logic0 : branch_logic
    port map (
      i_clk     => i_clk,
      i_ce      => w_phase_execute,
      i_in1     => w_reg_out1,
      i_in2     => w_reg_out2,
      i_func    => w_branch_func,
      o_branch  => w_take_branch
    );

  dmem_interface0 : dmem_interface
    port map (
      i_clk             => i_clk,
      i_ce              => w_phase_memory,
      i_addr            => w_alu_out,
      i_writedata       => w_reg_out2,
      i_rd              => w_load,
      i_wr              => w_store,
      i_func            => w_mem_func,
      o_readdata        => w_data_out,
      o_wait            => w_memory_wait,
      o_av_addr         => w_av_data_addr,
      o_av_byteenable   => w_av_data_byteenable,
      o_av_read         => w_av_data_read,
      o_av_write        => w_av_data_write,
      i_av_waitrequest  => w_av_data_waitrequest,
      o_av_writedata    => w_av_data_writedata,
      i_av_readdata     => w_av_data_readdata
    );

  imem_interface0 : imem_interface
    port map (
      i_clk             => i_clk,
      i_ce              => w_phase_fetch,
      i_pc              => w_pc,
      o_av_addr         => w_av_inst_addr,
      o_av_byteenable   => w_av_inst_byteenable,
      o_av_read         => w_av_inst_read,
      o_av_write        => w_av_inst_write,
      i_av_waitrequest  => w_av_inst_waitrequest,
      o_av_writedata    => w_av_inst_writedata,
      i_av_readdata     => w_av_inst_readdata,
      o_opcode          => w_opcode,
      o_wait            => w_fetch_wait
    );

  program_counter0 : program_counter
    port map (
      i_clk     => i_clk,
      i_rst     => i_rst,
      i_ce      => w_phase_write_back,
      i_load    => w_pc_load,
      i_value   => w_alu_out,
      o_pc      => w_pc,
      o_pc_next => w_pc_next
    );

end architecture behave;