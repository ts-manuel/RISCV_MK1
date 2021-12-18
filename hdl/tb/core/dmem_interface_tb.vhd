-- *********************************************************************
-- File: dmem_interface_tb.vhd
--
-- Data Memory Interface Testbench
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all; 
use std.env.finish;


entity dmem_interface_tb is
end entity;


architecture behave of dmem_interface_tb is

  constant CLK_P : time := 10 ns;

  signal r_clk            : std_logic := '0';
  signal r_ce             : std_logic := '0';
  signal r_addr           : std_logic_vector(31 downto 0) := (others=>'0');
  signal r_writedata      : std_logic_vector(31 downto 0) := (others=>'0');
  signal r_rd             : std_logic := '0';
  signal r_wr             : std_logic := '0';
  signal r_byte_enable    : std_logic_vector(3 downto 0) := (others=>'0');
  signal r_load_unsign    : std_logic := '0';
  signal w_readdata       : std_logic_vector(31 downto 0);
  signal w_wait           : std_logic;
  signal w_av_addr        : std_logic_vector(31 downto 0);
  signal w_av_writedata   : std_logic_vector(31 downto 0);
  signal w_av_byte_enable : std_logic_vector(3 downto 0);
  signal w_av_read        : std_logic;
  signal w_av_write       : std_logic;
  signal r_av_waitrequest : std_logic := '0';
  signal r_av_readdata    : std_logic_vector(31 downto 0) := (others=>'0');


  -- Test patters to apply
  type pattern_type is record
    storeddata  : std_logic_vector(31 downto 0);
    waitstates  : integer;
    byte_enable : std_logic_vector(3 downto 0);
    load_unsign : std_logic;
    readdata    : std_logic_vector(31 downto 0);
  end record;
  type pattern_array is array (natural range <>) of pattern_type;
  constant patterns : pattern_array := (
    (x"c3ed7a90",  0, "1111", '0', x"c3ed7a90"),
    (x"70008164",  1, "1111", '0', x"70008164"),
    (x"41660703",  4, "1111", '0', x"41660703"),
    (x"62b88b6c",  0, "0011", '0', x"ffff8b6c"),
    (x"6fda25f7",  1, "0011", '0', x"000025f7"),
    (x"9413823b",  4, "0011", '0', x"ffff823b"),
    (x"b6f2b37a",  0, "0011", '1', x"0000b37a"),
    (x"496c7f70",  1, "0011", '1', x"00007f70"),
    (x"bed1b161",  4, "0011", '1', x"0000b161"),
    (x"97f0794d",  0, "0001", '0', x"0000004d"),
    (x"012a7280",  1, "0001", '0', x"ffffff80"),
    (x"578856e4",  4, "0001", '0', x"ffffffe4"),
    (x"0ed68edb",  0, "0001", '1', x"000000db"),
    (x"854a3394",  1, "0001", '1', x"00000094"),
    (x"0b9997f3",  4, "0001", '1', x"000000f3")
  );


  -- converts logic vector to hex string
  function to_hstring (SLV : std_logic_vector) return string is
    variable L : LINE;
  begin
    hwrite(L,SLV);
    return L.all;
  end function to_hstring;


  component dmem_interface is
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
  end component dmem_interface;

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
    
    -- Test intermittent read
    for i in patterns'range loop
      r_ce  <= '1';
      r_rd  <= '1';
      r_wr  <= '0';
      r_byte_enable <= patterns(i).byte_enable;
      r_load_unsign <= patterns(i).load_unsign;
      r_addr  <= std_logic_vector(to_unsigned(i, r_addr'length));
      wait until rising_edge(r_clk);
      while w_wait = '1' loop
        wait until rising_edge(r_clk);
      end loop;
      r_ce  <= '0';
      wait until rising_edge(r_clk);
      assert (w_readdata = patterns(i).readdata) report "Failed test " & integer'image(i) & " READ = " & to_hstring(w_readdata) & " EXPECTED: " & to_hstring(patterns(i).readdata) severity failure;
    end loop;

    -- Test continous read
    for i in patterns'range loop
      r_ce  <= '1';
      r_rd  <= '1';
      r_wr  <= '0';
      r_byte_enable <= patterns(i).byte_enable;
      r_load_unsign <= patterns(i).load_unsign;
      r_addr  <= std_logic_vector(to_unsigned(i, r_addr'length));
      wait until rising_edge(r_clk);
      while w_wait = '1' loop
        wait until rising_edge(r_clk);
      end loop;
      assert (w_readdata = patterns(i).readdata) report "Failed test " & integer'image(i) & " READ = " & to_hstring(w_readdata) & " EXPECTED: " & to_hstring(patterns(i).readdata) severity failure;
    end loop;

    -- Test write
    r_ce  <= '1';
    r_rd  <= '0';
    r_wr  <= '1';
    r_load_unsign <= '0';
    r_byte_enable <= "1111";
    r_writedata   <= x"01234567";
    wait until rising_edge(r_clk);
    assert (w_av_write        = r_wr)           report "Failed write: write signal"       severity failure;
    assert (w_av_byte_enable  = r_byte_enable)  report "Failed write: byte enable signal" severity failure;
    assert (w_av_writedata    = r_writedata)    report "Failed write: writedata signal"   severity failure;
    r_byte_enable <= "0011";
    r_writedata   <= x"89012345";
    wait until rising_edge(r_clk);
    assert (w_av_write        = r_wr)           report "Failed write: write signal"       severity failure;
    assert (w_av_byte_enable  = r_byte_enable)  report "Failed write: byte enable signal" severity failure;
    assert (w_av_writedata    = r_writedata)    report "Failed write: writedata signal"   severity failure;
    r_byte_enable <= "0001";
    r_writedata   <= x"67891054";
    wait until rising_edge(r_clk);
    assert (w_av_write        = r_wr)           report "Failed write: write signal"       severity failure;
    assert (w_av_byte_enable  = r_byte_enable)  report "Failed write: byte enable signal" severity failure;
    assert (w_av_writedata    = r_writedata)    report "Failed write: writedata signal"   severity failure;
  
    -- End simulation
    finish;

  end process p_sim;


  -- Avalon bus emulation
  p_avalon : process (r_clk, w_av_addr, w_av_read)
    variable v_read   : boolean := false;
    variable v_cycle  : integer := 0;
  begin 

    if (w_av_read = '1' and v_read = false) then
      v_read := true;
    end if;

    if (v_read) then
      if (patterns(to_integer(unsigned(w_av_addr))).waitstates > v_cycle) then
        r_av_waitrequest <= '1';
        r_av_readdata <= x"00000000";
      else
        r_av_waitrequest <= '0';
        r_av_readdata <= patterns(to_integer(unsigned(w_av_addr))).storeddata;
      end if;
    end if;

    if (rising_edge(r_clk)) then
      if (v_read) then
        if (r_av_waitrequest = '0') then
          v_read  := false;
          v_cycle := 0;
        else
          v_cycle := v_cycle + 1;
        end if;
      end if;
    end if;

  end process p_avalon;


  dut : dmem_interface
    port map (
      i_clk             => r_clk,
      i_ce              => r_ce,
      i_addr            => r_addr,
      i_writedata       => r_writedata,
      i_rd              => r_rd,
      i_wr              => r_wr,
      i_byte_enable     => r_byte_enable,
      i_load_unsign     => r_load_unsign,
      o_readdata        => w_readdata,
      o_wait            => w_wait,
      o_av_addr         => w_av_addr,
      o_av_writedata    => w_av_writedata,
      o_av_byte_enable  => w_av_byte_enable,
      o_av_read         => w_av_read,
      o_av_write        => w_av_write,
      i_av_waitrequest  => r_av_waitrequest,
      i_av_readdata     => r_av_readdata
    );

end architecture behave;