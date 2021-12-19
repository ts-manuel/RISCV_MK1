-- *********************************************************************
-- File: imem_interface_tb.vhd
--
-- Instruction Memory Interface Testbench
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all; 
use std.env.finish;


entity imem_interface_tb is
end entity;


architecture behave of imem_interface_tb is

  constant CLK_P : time := 10 ns;

  signal r_clk            : std_logic := '0';
  signal r_ce             : std_logic := '0';
  signal r_pc             : std_logic_vector(31 downto 0) := (others=>'0');
  signal w_av_addr        : std_logic_vector(31 downto 0);
  signal w_av_read        : std_logic;
  signal r_av_waitrequest : std_logic := '0';
  signal r_av_readdata        : std_logic_vector(31 downto 0) := (others=>'0');
  signal w_opcode         : std_logic_vector(31 downto 0);
  signal w_wait           : std_logic;


  -- Test patters to apply
  type pattern_type is record
    data        : std_logic_vector(31 downto 0);
    waitstates  : integer;
  end record;
  type pattern_array is array (natural range <>) of pattern_type;
  constant patterns : pattern_array := (
    (x"9d03119a", 0),
    (x"1c332c2b", 0),
    (x"b4a66f37", 1),
    (x"88db2068", 1),
    (x"ad0e0e7e", 4),
    (x"f7d1cae2", 4),
    (x"3cf64644", 16),
    (x"9d2ffdcb", 0)
  );


  -- converts logic vector to hex string
  function to_hstring (SLV : std_logic_vector) return string is
    variable L : LINE;
  begin
    hwrite(L,SLV);
    return L.all;
  end function to_hstring;


  component imem_interface is
    port (
      i_clk             : in  std_logic;
      i_ce              : in  std_logic;
      i_pc              : in  std_logic_vector(31 downto 0);
      o_av_addr         : out std_logic_vector(31 downto 0);
      o_av_read         : out std_logic;
      i_av_waitrequest  : in  std_logic;
      i_av_readdata     : in  std_logic_vector(31 downto 0);
      o_opcode          : out std_logic_vector(31 downto 0);
      o_wait            : out std_logic
    );
  end component imem_interface;

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
      r_pc  <= std_logic_vector(to_unsigned(i, r_pc'length));
      wait until rising_edge(r_clk);
      while w_wait = '1' loop
        wait until rising_edge(r_clk);
      end loop;
      r_ce  <= '0';
      wait until rising_edge(r_clk);
      assert (w_opcode = patterns(i).data) report "Failed test " & integer'image(i) & " OPCODE = " & to_hstring(w_opcode) & " EXPECTED: " & to_hstring(patterns(i).data) severity failure;
    end loop;

    -- Test continous read
    for i in patterns'range loop
      r_ce  <= '1';
      r_pc  <= std_logic_vector(to_unsigned(i, r_pc'length));
      wait until rising_edge(r_clk);
      while w_wait = '1' loop
        wait until rising_edge(r_clk);
      end loop;
      assert (w_opcode = patterns(i).data) report "Failed test " & integer'image(i) & " OPCODE = " & to_hstring(w_opcode) & " EXPECTED: " & to_hstring(patterns(i).data) severity failure;
    end loop;
  
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
        r_av_readdata <= patterns(to_integer(unsigned(w_av_addr))).data;
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


  dut : imem_interface
    port map (
      i_clk             => r_clk,
      i_ce              => r_ce,
      i_pc              => r_pc,
      o_av_addr         => w_av_addr,
      o_av_read         => w_av_read,
      i_av_waitrequest  => r_av_waitrequest,
      i_av_readdata     => r_av_readdata,
      o_opcode          => w_opcode,
      o_wait            => w_wait
    );

end architecture behave;