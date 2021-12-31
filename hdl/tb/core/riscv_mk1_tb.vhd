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

  constant CLK_P : time := 10 ns;
  constant INST_WAIT_STATES : integer := 0; -- Wait states between instruction memory reads
  constant DATA_WAIT_STATES : integer := 0; -- Wait states between data memory reads

  signal r_clk                  : std_logic := '0';
  signal r_rst                  : std_logic := '0';
  signal w_av_inst_addr         : std_logic_vector(29 downto 0);
  signal w_av_inst_read         : std_logic;
  signal r_av_inst_waitrequest  : std_logic := '0';
  signal r_av_inst_readdata     : std_logic_vector(31 downto 0) := (others=>'0');
  signal w_av_data_read         : std_logic;
  signal w_av_data_write        : std_logic;
  signal w_av_data_byte_enable  : std_logic_vector(3 downto 0);
  signal w_av_data_addr         : std_logic_vector(29 downto 0);
  signal w_av_data_writedata    : std_logic_vector(31 downto 0);
  signal r_av_data_waitrequest  : std_logic := '0';
  signal r_av_data_readdata     : std_logic_vector(31 downto 0) := (others=>'0');


  component riscv_mk1 is
    port (
      i_clk                 : in  std_logic;
      i_rst                 : in  std_logic;
      o_av_inst_addr        : out std_logic_vector(29 downto 0);
      o_av_inst_read        : out std_logic;
      i_av_inst_waitrequest : in  std_logic;
      i_av_inst_readdata    : in  std_logic_vector(31 downto 0);
      o_av_data_read        : out std_logic;
      o_av_data_write       : out std_logic;
      o_av_data_byte_enable : out std_logic_vector(3 downto 0);
      o_av_data_addr        : out std_logic_vector(29 downto 0);
      o_av_data_writedata   : out std_logic_vector(31 downto 0);
      i_av_data_waitrequest : in  std_logic;
      i_av_data_readdata    : in  std_logic_vector(31 downto 0)
    );
  end component riscv_mk1;

  component avalon_bus is
    generic (
      g_addr_start  : integer;
      g_addr_stop   : integer;
      g_in_file     : string;
      g_out_file    : string
    );
    port (
      i_clk         : in  std_logic;
      i_read        : in  std_logic;
      i_write       : in  std_logic;
      o_waitrequest : out std_logic;
      i_bytenable   : in  std_logic_vector(3 downto 0);
      i_address     : in  std_logic_vector(29 downto 0);
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
    while (r_av_inst_readdata /= x"0000006f") loop
      wait until rising_edge(r_clk);
    end loop;

    -- End simulation
    finish;

  end process p_sim;


  av_inst : avalon_bus
    generic map (
      g_addr_start  => 0,
      g_addr_stop   => 65535,
      g_in_file     => "code/fibonacci/fibo.vhdl",
      g_out_file    => ""
    )
    port map (
      i_clk         => r_clk,
      i_read        => w_av_inst_read,
      i_write       => '0',
      o_waitrequest => r_av_inst_waitrequest,
      i_bytenable   => "0000",
      i_address     => w_av_inst_addr,
      i_writedata   => x"00000000",
      o_readdata    => r_av_inst_readdata
    );


    av_data : avalon_bus
    generic map (
      g_addr_start  => 16#20000000# /4,
      g_addr_stop   => 16#20010000# /4,
      g_in_file     => "",
      g_out_file    => ""
    )
    port map (
      i_clk         => r_clk,
      i_read        => w_av_data_read,
      i_write       => w_av_data_write,
      o_waitrequest => r_av_data_waitrequest,
      i_bytenable   => w_av_data_byte_enable,
      i_address     => w_av_data_addr,
      i_writedata   => w_av_data_writedata,
      o_readdata    => r_av_data_readdata
    );


  cpu : riscv_mk1
    port map (
      i_clk                 => r_clk,
      i_rst                 => r_rst,
      o_av_inst_addr        => w_av_inst_addr,
      o_av_inst_read        => w_av_inst_read,
      i_av_inst_waitrequest => r_av_inst_waitrequest,
      i_av_inst_readdata    => r_av_inst_readdata,
      o_av_data_read        => w_av_data_read,
      o_av_data_write       => w_av_data_write,
      o_av_data_byte_enable => w_av_data_byte_enable,
      o_av_data_addr        => w_av_data_addr,
      o_av_data_writedata   => w_av_data_writedata,
      i_av_data_waitrequest => r_av_data_waitrequest,
      i_av_data_readdata    => r_av_data_readdata
    );

end architecture behave;