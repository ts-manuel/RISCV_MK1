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
--  i_func:           selects between 8/16/32 bit read / write and whe to sign extend the data
--  o_readdata:       output data
--  o_wait:           output wait signals
--  o_av_addr:        Avalon address
--  o_av_byteenable:  Avalon byte enable
--  o_av_read:        Avalon read
--  o_av_write:       Avalon write
--  i_av_waitrequest: Avalon wait request
--  o_av_writedata:   Avalon write data
--  i_av_readdata:    Avalon read data
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
end entity dmem_interface;


architecture behave of dmem_interface is

  constant c_byte_mask : std_logic_vector(3 downto 0) := "0001";
  constant c_word_mask : std_logic_vector(3 downto 0) := "0011";

  signal w_offset : integer range 0 to 3;
  signal w_data_in_aligned : std_logic_vector(31 downto 0);
  signal w_byte  : std_logic_vector(31 downto 0);
  signal w_word  : std_logic_vector(31 downto 0);
  signal w_ubyte : std_logic_vector(31 downto 0);
  signal w_uword : std_logic_vector(31 downto 0);
  
begin

  -- Allign input data to 32-bit boundary
  w_offset <= to_integer(unsigned(i_addr(1 downto 0)));
  w_data_in_aligned <= std_logic_vector(shift_right(unsigned(i_av_readdata), w_offset*8));

  -- Sign extend input data
  w_byte(7 downto 0)    <= w_data_in_aligned(7 downto 0);
  w_byte(31 downto 8)   <= (others=>w_data_in_aligned(7));
  w_word(15 downto 0)   <= w_data_in_aligned(15 downto 0);
  w_word(31 downto 16)  <= (others=>w_data_in_aligned(15));

  w_ubyte(7 downto 0)   <= w_data_in_aligned(7 downto 0);
  w_ubyte(31 downto 8)  <= (others=>'0');
  w_uword(15 downto 0)  <= w_data_in_aligned(15 downto 0);
  w_uword(31 downto 16) <= (others=>'0');


  -- Output signals
  o_readdata <= w_byte  when (i_func = "000") else
                w_word  when (i_func = "001") else
                w_ubyte when (i_func = "100") else
                w_uword when (i_func = "101") else
                w_data_in_aligned;

  o_wait  <= i_av_waitrequest;


  -- Avalon output signals
  o_av_addr         <= i_addr(31 downto 2);

  o_av_writedata    <= std_logic_vector(shift_left(unsigned(i_writedata), w_offset*8));

  o_av_byteenable   <=  std_logic_vector(shift_left(unsigned(c_byte_mask), w_offset)) when (i_func(1 downto 0) = "00") else
                        std_logic_vector(shift_left(unsigned(c_word_mask), w_offset)) when (i_func(1 downto 0) = "01") else
                        "1111";

  o_av_read         <= '1' when (i_ce = '1' and i_rd = '1') else '0';
  o_av_write        <= '1' when (i_ce = '1' and i_wr = '1') else '0';

end architecture behave;