-- *********************************************************************
-- File: video_gen_tb.vhd
--
-- Stereo DAC Test Bench
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all; 
use std.env.finish;


entity video_gen_tb is
end entity;


architecture behave of video_gen_tb is

  constant CLK_P      : time    := 10 ns;
  constant FIFO_SIZE  : integer := 16;

  signal r_clk            : std_logic := '0';
  signal w_av_acknowledge : std_logic;
  signal w_av_irq         : std_logic;
  signal r_av_address     : std_logic_vector(3 downto 0);
  signal r_av_bus_enable  : std_logic;
  signal r_av_byte_enable : std_logic_vector(3 downto 0);
  signal r_av_rw          : std_logic;
  signal r_av_write_data  : std_logic_vector(31 downto 0);
  signal w_av_read_data   : std_logic_vector(31 downto 0);
  signal w_vga_r          : std_logic_vector(3 downto 0);
  signal w_vga_g          : std_logic_vector(3 downto 0);
  signal w_vga_b          : std_logic_vector(3 downto 0);
  signal w_vga_hs         : std_logic;
  signal w_vga_vs         : std_logic;


  type t_array is array (natural range <>) of std_logic_vector(31 downto 0);
  constant m_pixels : t_array := (
    x"00000001",
    x"00000002",
    x"00000003",
    x"00000004",
    x"00000005",
    x"00000006",
    x"00000007",
    x"00000008",

    x"00000010",
    x"00000020",
    x"00000030",
    x"00000040",
    x"00000050",
    x"00000060",
    x"00000070",
    x"00000080",

    x"00000100",
    x"00000200",
    x"00000300",
    x"00000400",
    x"00000500",
    x"00000600",
    x"00000700",
    x"00000800",

    x"00001000",
    x"00002000",
    x"00003000",
    x"00004000",
    x"00005000",
    x"00006000",
    x"00007000",
    x"00008000"
  );


  -- Write 32 bit word to avalon interface
  procedure p_AV_READ (
    variable i_addr : in  std_logic_vector(3 downto 0);
    variable o_data : out std_logic_vector(31 downto 0);
    -- Avalon signals
    signal i_av_acknowledge : in  std_logic;
    signal o_av_address     : out std_logic_vector(3 downto 0);
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
    variable i_addr : in  std_logic_vector(3 downto 0);
    variable i_data : in  std_logic_vector(31 downto 0);
    -- Avalon signals
    signal i_av_acknowledge : in  std_logic;
    signal o_av_address     : out std_logic_vector(3 downto 0);
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

  component video_gen is
    generic (
      FIFO_SIZE : integer
    );
    port (
      i_clk           : in  std_logic;
      av_acknowledge  : out std_logic;
      av_irq          : out std_logic;
      av_address      : in  std_logic_vector(3 downto 0);
      av_bus_enable   : in  std_logic;
      av_byte_enable  : in  std_logic_vector(3 downto 0);
      av_rw           : in  std_logic;
      av_write_data   : in  std_logic_vector(31 downto 0);
      av_read_data    : out std_logic_vector(31 downto 0);
      o_vga_r         : out std_logic_vector(3 downto 0);
      o_vga_g         : out std_logic_vector(3 downto 0);
      o_vga_b         : out std_logic_vector(3 downto 0);
      o_vga_hs        : out std_logic;
      o_vga_vs        : out std_logic
    );
  end component video_gen;

begin

  -- Clock generation
  p_clk : process
  begin
    wait for CLK_P * 0.5;
    r_clk <= not r_clk;
  end process p_clk;

  -- Simulation
  p_sim : process
    variable v_address    : std_logic_vector( 3 downto 0);
    variable v_write_data : std_logic_vector(31 downto 0);
    variable v_read_data  : std_logic_vector(31 downto 0);
  begin

    -- set clock and pixel divider
    v_address     := "1000";
    v_write_data  := x"00000188";
    p_AV_WRITE(v_address, v_write_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);

    v_address     := "1000";
    p_AV_READ (v_address, v_read_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);

    assert v_read_data(11 downto 0) = v_write_data(11 downto 0)
      report "Avalon read failed, expected: " & to_hstring(v_write_data) & " read: " & to_hstring(v_read_data)
      severity failure;


    -- wait for horizontal sync and check read
    while (w_vga_hs = '1') loop
      wait for CLK_P;
    end loop;

    v_address     := "0100";
    p_AV_READ (v_address, v_read_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);

    assert v_read_data(16) = '0'
      report "Avalon read failed, expected v_sync to be '0'"
      severity failure;
    assert v_read_data(17) = '1'
      report "Avalon read failed, expected h_sync to be '1'"
      severity failure;

    while (w_vga_hs = '0') loop
      wait for CLK_P;
    end loop;

    v_address     := "0100";
    p_AV_READ (v_address, v_read_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);

    assert v_read_data(16) = '0'
      report "Avalon read failed, expected v_sync to be '0'"
      severity failure;
    assert v_read_data(17) = '0'
      report "Avalon read failed, expected h_sync to be '0'"
      severity failure;


    -- wait for vertical sync and check read
    while (w_vga_vs = '1') loop
      wait for CLK_P;
    end loop;

    v_address     := "0100";
    p_AV_READ (v_address, v_read_data,
      w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);

    assert v_read_data(16) = '1'
      report "Avalon read failed, expected v_sync to be '1'"
      severity failure;
    assert v_read_data(17) = '0'
      report "Avalon read failed, expected h_sync to be '1'"
      severity failure;


    -- write data to fifo
    for i in m_pixels'range loop

      v_address     := "0100";
      p_AV_READ (v_address, v_read_data,
        w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);
      while (to_integer(unsigned(v_read_data(15 downto 0))) = 0) loop
        p_AV_READ (v_address, v_read_data,
          w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);
      end loop;

      v_address     := "0000";
      v_write_data  := m_pixels(i);
      p_AV_WRITE(v_address, v_write_data,
        w_av_acknowledge, r_av_address, r_av_bus_enable, r_av_byte_enable, r_av_rw, r_av_write_data, w_av_read_data);
    end loop;

    -- ait for a video frame
    wait for CLK_P*800*524*2;

    finish;
  end process p_sim;


  video_gen0 : video_gen
    generic map (
      FIFO_SIZE => FIFO_SIZE
    )
    port map (
      i_clk           => r_clk,
      av_acknowledge  => w_av_acknowledge,
      av_irq          => w_av_irq,
      av_address      => r_av_address,
      av_bus_enable   => r_av_bus_enable,
      av_byte_enable  => r_av_byte_enable,
      av_rw           => r_av_rw,
      av_write_data   => r_av_write_data,
      av_read_data    => w_av_read_data,
      o_vga_r         => w_vga_r,
      o_vga_g         => w_vga_g,
      o_vga_b         => w_vga_b,
      o_vga_hs        => w_vga_hs,
      o_vga_vs        => w_vga_vs
    );

end architecture behave;