-- *********************************************************************
-- File: avalon_bus.vhd
--
-- Avalon bus emulation
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all; 
use std.env.finish;


entity avalon_bus is
    generic (
      g_addr_start  : integer := 0;
      g_addr_stop   : integer := 2**30;
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
end entity avalon_bus;


architecture behave of avalon_bus is

  -- Internal memory
  type t_Memory is array (0 to (g_addr_stop - g_addr_start)) of std_logic_vector(31 downto 0);
  signal memory : t_Memory;


  signal w_read_wait : std_logic;
  signal w_write_wait : std_logic;
  signal w_addr : integer;

begin

  w_addr        <= to_integer(unsigned(i_address)) - g_addr_start;
  o_waitrequest <= w_read_wait or w_write_wait;

  -- Initialize memory with data from input file
  p_load : process
    file      v_file    : text;
    variable  v_status  : file_open_status;
    variable  v_line    : line;
    variable  v_addr    : integer := 0;
    variable  v_data    : std_logic_vector(31 downto 0);
  begin

    if (g_in_file /= "") then
      file_open(v_status, v_file, g_in_file, READ_MODE);
      assert (v_status = OPEN_OK) report "Unable to open input file: " & g_in_file severity failure;

      while (not endfile(v_file)) loop
        readline(v_file, v_line);

        assert v_addr <= g_addr_stop - g_addr_start report "To many items in input file" severity failure;
        hread(v_line, v_data);
        memory(v_addr) <= v_data;
        wait for 0 ps;
        report "Read: " & to_hstring(v_data) & " At address: " & integer'image(v_addr * 4);
        report "Memory: " & to_hstring(memory(v_addr));
        v_addr := v_addr + 1;
      end loop;
    end if;

    wait;
  end process p_load;


  -- Handle read request from bus
  p_read : process (i_clk, i_read)
  begin
    w_read_wait <= '0';

    if (i_read = '1') then
      if ((w_addr >= 0) and (w_addr <= g_addr_stop - g_addr_start)) then 
        o_readdata <= memory(w_addr);
      else
        o_readdata <= (others=>'0');
      end if;
    end if;

  end process p_read;


  -- Handle write request from bus
  p_write : process (i_clk, i_write)
    variable  v_init    : boolean := true;
  begin

    -- Don't drive the memory during initialization
    if(v_init) then
      v_init := false;
      for i in memory'range loop
        memory(i) <= x"ZZZZZZZZ";
      end loop;
    end if;

    w_write_wait <= '0';

    if (i_write = '1') then
      if ((w_addr >= 0) and (w_addr <= g_addr_stop - g_addr_start)) then 
        memory(w_addr)( 7 downto  0) <= i_writedata( 7 downto  0) when i_bytenable(0) = '1' else memory(w_addr)( 7 downto  0);
        memory(w_addr)(15 downto  8) <= i_writedata(15 downto  8) when i_bytenable(1) = '1' else memory(w_addr)(15 downto  8);
        memory(w_addr)(23 downto 16) <= i_writedata(23 downto 16) when i_bytenable(2) = '1' else memory(w_addr)(23 downto 16);
        memory(w_addr)(31 downto 24) <= i_writedata(31 downto 24) when i_bytenable(3) = '1' else memory(w_addr)(31 downto 24);
    
        report "AV Write: " & to_hstring(i_writedata) & " at addr: " & to_hstring(to_unsigned(w_addr * 4, 32));
      else
        
      end if;
    end if;

  end process p_write;

  
end architecture behave;