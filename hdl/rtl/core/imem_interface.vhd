-- *********************************************************************
-- File: imem_interface.vhd
--
-- CPU Instruction memory Interface
--
-- Generic:
--
-- Port:
--  i_clk:          clock input
--  i_ce:           clock enable active HIGH
--  i_pc:           address to fetch
--  o_addr:         Avalon address
--  o_read:         Avalon read
--  i_waitrequest:  Avalon waitrequest
--  i_data:         Avalon input data
--  o_opcode:       fetched opcode
--  o_wait:         wait signal
--
-- *********************************************************************


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity imem_interface is
  port (
    i_clk         : in  std_logic;
    i_ce          : in  std_logic;
    i_pc          : in  std_logic_vector(31 downto 0);
    o_addr        : out std_logic_vector(31 downto 0);
    o_read        : out std_logic;
    i_waitrequest : in  std_logic;
    i_data        : in  std_logic_vector(31 downto 0);
    o_opcode      : out std_logic_vector(31 downto 0);
    o_wait        : out std_logic
  );
end entity imem_interface;


architecture behave of imem_interface is
begin

  -- Signal remapping
  o_read    <= i_ce;
  o_addr    <= i_pc;
  o_wait    <= i_waitrequest;
  o_opcode  <= i_data;
  
end architecture behave;