-- *********************************************************************
-- File: hpc_tb.vhd
--
-- Hardware Performance Counter Test Bench
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all; 
use std.env.finish;


entity hpc_tb is
end entity;


architecture behave of hpc_tb is

  constant CLK_P : time := 10 ns;

  signal r_clk              : std_logic := '0';
  signal r_rst              : std_logic := '0'; 
  signal w_av_acknowledge   : std_logic;
  signal w_av_irq           : std_logic;
  signal r_av_address       : std_logic_vector(5 downto 0);
  signal r_av_bus_enable    : std_logic;
  signal r_av_byte_enable   : std_logic_vector(3 downto 0);
  signal r_av_rw            : std_logic;
  signal r_av_write_data    : std_logic_vector(31 downto 0);
  signal w_av_read_data     : std_logic_vector(31 downto 0);

  signal w_cpu_debug_vector : std_logic_vector(31 downto 0);
  signal r_cpu_fetch        : std_logic := '0';


  -- Write 32 bit word to avalon interface
  procedure p_AV_READ (
    variable i_addr : in  std_logic_vector(5 downto 0);
    variable o_data : out std_logic_vector(31 downto 0);
    -- Avalon signals
    signal i_av_acknowledge : in  std_logic;
    signal o_av_address     : out std_logic_vector(5 downto 0);
    signal o_av_bus_enable  : out std_logic;
    signal o_av_byte_enable : out std_logic_vector(3 downto 0);
    signal o_av_rw          : out std_logic;
    signal o_av_write_data  : out std_logic_vector(31 downto 0);
    signal i_av_read_data   : in  std_logic_vector(31 downto 0)
    ) is
  begin
    o_av_address      <= i_addr;
    o_av_bus_enable   <= '1';
    o_av_rw           <= '1';
    o_av_byte_enable  <= "1111";
    o_av_write_data   <= x"00000000";
    wait for CLK_P;

    -- whait for the transaction to finish
    while (i_av_acknowledge = '0') loop
      wait for CLK_P;
    end loop;
    o_av_bus_enable <= '0';
    o_data          := i_av_read_data;
  end p_AV_READ;

  -- Write 32 bit word to avalon interface
  procedure p_AV_WRITE (
    variable i_addr : in  std_logic_vector(5 downto 0);
    variable i_data : in  std_logic_vector(31 downto 0);
    -- Avalon signals
    signal i_av_acknowledge : in  std_logic;
    signal o_av_address     : out std_logic_vector(5 downto 0);
    signal o_av_bus_enable  : out std_logic;
    signal o_av_byte_enable : out std_logic_vector(3 downto 0);
    signal o_av_rw          : out std_logic;
    signal o_av_write_data  : out std_logic_vector(31 downto 0);
    signal i_av_read_data   : in  std_logic_vector(31 downto 0)
    ) is
  begin
    o_av_address      <= i_addr;
    o_av_bus_enable   <= '1';
    o_av_rw           <= '0';
    o_av_byte_enable  <= "1111";
    o_av_write_data   <= i_data;
    wait for CLK_P;

    -- whait for the transaction to finish
    while (i_av_acknowledge = '0') loop
      wait for CLK_P;
    end loop;
    o_av_bus_enable   <= '0';
  end p_AV_WRITE;

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


  component hpc is
    port (
      i_clk               : in  std_logic;
      i_rst               : in  std_logic;
      av_acknowledge      : out std_logic;
      av_irq              : out std_logic;
      av_address          : in  std_logic_vector(5 downto 0);
      av_bus_enable       : in  std_logic;
      av_byte_enable      : in  std_logic_vector(3 downto 0);
      av_rw               : in  std_logic;
      av_write_data       : in  std_logic_vector(31 downto 0);
      av_read_data        : out std_logic_vector(31 downto 0);
      i_cpu_debug_vector  : in  std_logic_vector(31 downto 0)
    );
  end component hpc;
begin

  -- Clock generation
  p_clk : process
  begin
    wait for CLK_P * 0.5;
    r_clk <= not r_clk;
  end process p_clk;

  -- CPU emulation
  w_cpu_debug_vector(0)           <= r_cpu_fetch;
  w_cpu_debug_vector(31 downto 1) <= (others=>'0');
  p_cpu : process (r_clk)
  begin
    if rising_edge(r_clk) then
      r_cpu_fetch <= not r_cpu_fetch;
    end if;
  end process;

  -- Simulation
  p_sim : process
    variable v_address    : std_logic_vector( 5 downto 0);
    variable v_write_data : std_logic_vector(31 downto 0);
    variable v_read_data  : std_logic_vector(31 downto 0);
    variable v_clk_cnt_l  : std_logic_vector(31 downto 0);
    variable v_clk_cnt_h  : std_logic_vector(31 downto 0);
  begin
    -- Reset counters
    r_rst <= '1';
    wait for CLK_P;
    r_rst <= '0';

    wait for CLK_P*10;

    -- Chek if counters start after reset
    v_address     := "000000";     -- control
    v_write_data  := x"00000008"; -- snapshot
    p_AV_WRITE(v_address, v_write_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);

    v_address     := "000100";      -- clock counter low
    p_AV_READ (v_address, v_read_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);
    assert v_read_data = x"00000000"
      report "Start after reset failed, expected: " & to_hstring(x"00000000") & " read: " & to_hstring(v_read_data)
      severity failure;
    v_address     := "001000";     -- clock counter high
    p_AV_READ (v_address, v_read_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);
    assert v_read_data = x"00000000"
      report "Start after reset failed, expected: " & to_hstring(x"00000000") & " read: " & to_hstring(v_read_data)
      severity failure;

    -- Start counters
    v_address     := "000000";     -- control
    v_write_data  := x"00000001"; -- start
    p_AV_WRITE(v_address, v_write_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);

    wait for CLK_P*10;

    v_address     := "000000";     -- control
    v_write_data  := x"00000008"; -- snapshot
    p_AV_WRITE(v_address, v_write_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);

    v_address     := "000100";      -- clock counter low
    p_AV_READ (v_address, v_read_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);
    assert v_read_data = x"0000000A"
      report "Start after reset failed, expected: " & to_hstring(x"0000000A") & " read: " & to_hstring(v_read_data)
      severity failure;
    v_address     := "001000";     -- clock counter high
    p_AV_READ (v_address, v_read_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);
    assert v_read_data = x"00000000"
      report "Start after reset failed, expected: " & to_hstring(x"00000000") & " read: " & to_hstring(v_read_data)
      severity failure;

    v_address     := "001100";      -- instruction counter low
    p_AV_READ (v_address, v_read_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);
    assert v_read_data = x"00000005"
      report "Start after reset failed, expected: " & to_hstring(x"00000005") & " read: " & to_hstring(v_read_data)
      severity failure;
    v_address     := "010000";     -- instruction counter high
    p_AV_READ (v_address, v_read_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);
    assert v_read_data = x"00000000"
      report "Start after reset failed, expected: " & to_hstring(x"00000000") & " read: " & to_hstring(v_read_data)
      severity failure;

    -- Clear counters
    v_address     := "000000";     -- control
    v_write_data  := x"00000004"; -- clear
    p_AV_WRITE(v_address, v_write_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);

    v_address     := "000000";     -- control
    v_write_data  := x"00000008"; -- snapshot
    p_AV_WRITE(v_address, v_write_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);

    v_address     := "000100";      -- clock counter low
    p_AV_READ (v_address, v_read_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);
    assert v_read_data = x"00000001"
      report "Clear counters failed, expected: " & to_hstring(x"00000001") & " read: " & to_hstring(v_read_data)
      severity failure;
    v_address     := "001000";     -- clock counter high
    p_AV_READ (v_address, v_read_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);
    assert v_read_data = x"00000000"
      report "Clear counters failed, expected: " & to_hstring(x"00000000") & " read: " & to_hstring(v_read_data)
      severity failure;

    wait for CLK_P*64;
    -- Stop counters
    v_address     := "000000";     -- control
    v_write_data  := x"00000002"; -- stop
    p_AV_WRITE(v_address, v_write_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);

    v_address     := "000000";     -- control
    v_write_data  := x"00000008"; -- snapshot
    p_AV_WRITE(v_address, v_write_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);
    v_address     := "000100";      -- clock counter low
    p_AV_READ (v_address, v_read_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);
    v_clk_cnt_l := v_read_data;
    v_address     := "001000";     -- clock counter high
    p_AV_READ (v_address, v_read_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);
    v_clk_cnt_h := v_read_data;

      wait for CLK_P*4;

    v_address     := "000000";     -- control
    v_write_data  := x"00000008"; -- snapshot
    p_AV_WRITE(v_address, v_write_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);
    v_address     := "000100";      -- clock counter low
    p_AV_READ (v_address, v_read_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);
    assert v_read_data = v_clk_cnt_l
      report "Stop counters failed, expected: " & to_hstring(v_clk_cnt_l) & " read: " & to_hstring(v_read_data)
      severity failure;
    v_address     := "001000";     -- clock counter high
    p_AV_READ (v_address, v_read_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);
    assert v_read_data = v_clk_cnt_h
      report "Stop counters failed, expected: " & to_hstring(v_clk_cnt_h) & " read: " & to_hstring(v_read_data)
      severity failure;

    finish;
  end process p_sim;



  hpc0 : hpc
    port map (
      i_clk               => r_clk,
      i_rst               => r_rst,
      av_acknowledge      => w_av_acknowledge,
      av_irq              => w_av_irq,
      av_address          => r_av_address,
      av_bus_enable       => r_av_bus_enable,
      av_byte_enable      => r_av_byte_enable,
      av_rw               => r_av_rw,
      av_write_data       => r_av_write_data,
      av_read_data        => w_av_read_data,
      i_cpu_debug_vector  => w_cpu_debug_vector
    );

end architecture behave;