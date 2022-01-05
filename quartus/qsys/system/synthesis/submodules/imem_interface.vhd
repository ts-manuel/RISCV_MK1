-- *********************************************************************
-- File: imem_interface.vhd
--
-- CPU Instruction memory Interface
--
-- Generic:
--
-- Port:
--  i_clk:            clock input
--  i_ce:             clock enable active HIGH
--  i_pc:             address to fetch
--  o_av_addr:        Avalon address
--  o_av_byteenable:  Avalon byteenable (always 0xf)
--  o_av_read:        Avalon read
--  o_av_write:       Avalon write      (always 0)
--  i_av_waitrequest: Avalon waitrequest
--  o_av_writedata:   Avalon writedata  (always 0)
--  i_av_data:        Avalon input data
--  o_opcode:         fetched opcode
--  o_wait:           wait signal
--
-- *********************************************************************


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity imem_interface is
  port (
    i_clk             : in  std_logic;
    i_ce              : in  std_logic;
    i_pc              : in  std_logic_vector(31 downto 0);
    -- Avalon master
    o_av_addr         : out std_logic_vector(29 downto 0);
    o_av_byteenable   : out std_logic_vector(3 downto 0);
    o_av_read         : out std_logic;
    o_av_write        : out std_logic;
    i_av_waitrequest  : in  std_logic;
    o_av_writedata    : out std_logic_vector(31 downto 0);
    i_av_readdata     : in  std_logic_vector(31 downto 0);
    -- Output
    o_opcode          : out std_logic_vector(31 downto 0);
    o_wait            : out std_logic
  );
end entity imem_interface;


architecture behave of imem_interface is
begin

  -- Signal remapping
  o_av_addr       <= i_pc(31 downto 2);
  o_av_byteenable <= "1111";
  o_av_read       <= i_ce;
  o_av_write      <= '0';
  o_wait          <= i_av_waitrequest;
  o_av_writedata  <= x"00000000";
  o_opcode        <= i_av_readdata;
  
end architecture behave;