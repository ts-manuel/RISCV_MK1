-- *********************************************************************
-- File: dmem_interface.vhd
--
-- CPU Data memory Interface
--
-- Generic:
--
-- Port:
--  i_clk:            clock input
--  i_ce:             clock enable active HIGH
--  i_addr:           address to read / write
--  i_writedata:      input write data
--  i_rd:             read signal
--  i_wr:             write signal
--  i_byte_enable:    selects between 8/16/32 bit read / write
--  i_load_unsign:    when low data is sign extended on 8bit and 16bit reads
--  o_readdata:       output data
--  o_wait:           output wait signals
--  o_av_addr:        Avalon address
--  o_av_data:        Avalon write data
--  o_av_byte_enable: Avalon byte enable
--  o_av_read:        Avalon read
--  o_av_write:       Avalon write
--  i_av_waitrequest: Avalon wait request
--  i_av_data:        Avalon read data
--
-- *********************************************************************


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity dmem_interface is
  port (
    i_clk             : in  std_logic;
    i_ce              : in  std_logic;
    i_addr            : in  std_logic_vector(31 downto 0);
    i_writedata       : in  std_logic_vector(31 downto 0);
    i_rd              : in  std_logic;
    i_wr              : in  std_logic;
    i_byte_enable     : in  std_logic_vector(3 downto 0);
    i_load_unsign     : in  std_logic;
    o_readdata        : out std_logic_vector(31 downto 0);
    o_wait            : out std_logic;
    o_av_addr         : out std_logic_vector(31 downto 0);
    o_av_writedata    : out std_logic_vector(31 downto 0);
    o_av_byte_enable  : out std_logic_vector(3 downto 0);
    o_av_read         : out std_logic;
    o_av_write        : out std_logic;
    i_av_waitrequest  : in  std_logic;
    i_av_readdata     : in  std_logic_vector(31 downto 0)
  );
end entity dmem_interface;


architecture behave of dmem_interface is

  signal w_byte  : std_logic_vector(31 downto 0);
  signal w_word  : std_logic_vector(31 downto 0);
  signal w_ubyte : std_logic_vector(31 downto 0);
  signal w_uword : std_logic_vector(31 downto 0);

begin

  -- Sign extend data input
  w_byte(7 downto 0)    <= i_av_readdata(7 downto 0);
  w_byte(31 downto 8)   <= (others=>i_av_readdata(7));
  w_word(15 downto 0)   <= i_av_readdata(15 downto 0);
  w_word(31 downto 16)  <= (others=>i_av_readdata(15));

  w_ubyte(7 downto 0)   <= i_av_readdata(7 downto 0);
  w_ubyte(31 downto 8)  <= (others=>'0');
  w_uword(15 downto 0)  <= i_av_readdata(15 downto 0);
  w_uword(31 downto 16) <= (others=>'0');


  -- Output signals
  o_readdata <= w_byte  when (i_byte_enable = "0001" and i_load_unsign = '0') else
                w_word  when (i_byte_enable = "0011" and i_load_unsign = '0') else
                w_ubyte when (i_byte_enable = "0001" and i_load_unsign = '1') else
                w_uword when (i_byte_enable = "0011" and i_load_unsign = '1') else
                i_av_readdata;

  o_wait  <= i_av_waitrequest;


  -- Avalon output signals
  o_av_addr         <= i_addr;
  o_av_writedata    <= i_writedata;
  o_av_byte_enable  <= i_byte_enable;
  o_av_read         <= '1' when (i_ce = '1' and i_rd = '1') else '0';
  o_av_write        <= '1' when (i_ce = '1' and i_wr = '1') else '0';

end architecture behave;