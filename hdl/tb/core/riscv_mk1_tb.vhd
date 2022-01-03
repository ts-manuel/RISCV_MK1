-- *********************************************************************
-- File: riscv_mk1_tb.vhd
--
-- RISC-V MK1 CPU Core Testbench
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all; 
use std.env.finish;


entity riscv_mk1_tb is
end entity;


architecture behave of riscv_mk1_tb is

  -- *********************************************************************
  -- Testbench parameters
  constant MEM_SIZE       : integer := 2**16; -- 64 Kbyte
  constant MEM_INIT_FILE  : string  := "../code/fibonacci/bin/fibo.vhdl";
  constant MEM_TRACE_FILE : string  := "tb_out/fibo_trace.txt";
  constant WAIT_STATES    : integer := 0;     -- Memory wait states
  -- *********************************************************************

  constant CLK_P : time := 10 ns;
  
  signal r_clk            : std_logic := '0';
  signal r_rst            : std_logic := '0';
  signal w_av_addr        : std_logic_vector(29 downto 0);
  signal w_av_byteenable  : std_logic_vector(3 downto 0);
  signal w_av_read        : std_logic;
  signal w_av_write       : std_logic;
  signal w_av_waitrequest : std_logic := '0';
  signal w_av_writedata   : std_logic_vector(31 downto 0);
  signal w_av_readdata    : std_logic_vector(31 downto 0) := (others=>'0');


  component riscv_mk1 is
    port (
      i_clk             : in  std_logic;
      i_rst             : in  std_logic;
      o_av_addr         : out std_logic_vector(29 downto 0);
      o_av_byteenable   : out std_logic_vector(3 downto 0);
      o_av_read         : out std_logic;
      o_av_write        : out std_logic;
      i_av_waitrequest  : in  std_logic;
      o_av_writedata    : out std_logic_vector(31 downto 0);
      i_av_readdata     : in  std_logic_vector(31 downto 0)
    );
  end component riscv_mk1;

  component avalon_bus is
    generic (
      g_addr_start  : integer;
      g_addr_stop   : integer;
      g_init_file   : string;
      g_trace_file  : string;
      g_wait_states : integer
    );
    port (
      i_clk         : in  std_logic;
      i_address     : in  std_logic_vector(29 downto 0);
      i_bytenable   : in  std_logic_vector(3 downto 0);
      i_read        : in  std_logic;
      i_write       : in  std_logic;
      o_waitrequest : out std_logic;
      i_writedata   : in  std_logic_vector(31 downto 0);
      o_readdata    : out std_logic_vector(31 downto 0)
    );
  end component avalon_bus;

begin

  -- Clock generation
  p_clk : process
  begin
    wait for CLK_P * 0.5;
    r_clk <= not r_clk;
  end process p_clk;


  -- Run
  p_sim : process
  begin

    r_rst <= '1';
    wait until rising_edge(r_clk);
    r_rst <= '0';
    wait until rising_edge(r_clk);

    -- Run until (JALR x0 0) instruction (infinite loop)
    while (w_av_readdata /= x"0000006f") loop
      wait until rising_edge(r_clk);
    end loop;

    -- End simulation
    finish;

  end process p_sim;


  av_bus : avalon_bus
    generic map (
      g_addr_start  => 0,
      g_addr_stop   => MEM_SIZE,
      g_init_file   => MEM_INIT_FILE,
      g_trace_file  => MEM_TRACE_FILE,
      g_wait_states => WAIT_STATES
    )
    port map (
      i_clk         => r_clk,
      i_address     => w_av_addr,
      i_bytenable   => w_av_byteenable,
      i_read        => w_av_read,
      i_write       => w_av_write,
      o_waitrequest => w_av_waitrequest,
      i_writedata   => w_av_writedata,
      o_readdata    => w_av_readdata
    );


  cpu : riscv_mk1
    port map (
      i_clk            => r_clk,
      i_rst            => r_rst,
      o_av_addr        => w_av_addr,
      o_av_byteenable  => w_av_byteenable,
      o_av_read        => w_av_read,
      o_av_write       => w_av_write,
      i_av_waitrequest => w_av_waitrequest,
      o_av_writedata   => w_av_writedata,
      i_av_readdata    => w_av_readdata
    );

end architecture behave;