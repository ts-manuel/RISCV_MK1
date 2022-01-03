-- *********************************************************************
-- File: avalon_bus.vhd
--
-- Avalon bus emulation
--
-- Memory initialized from input file
-- Writes to memory are saved in the output file
--
-- Generic:
--  g_addr_start:   memory start address  (4 byte aligned)
--  g_addr_stop:    memory stop addres    (4 Byte aligned)
--  g_init_file:    input file with memory content
--  g_trace_file:   output file where to log memory writes
--  g_wait_states:  wait states to insert between transfers
-- Port:
--  i_clk:          clock input
--  i_address:      address to read or write
--  i_bytenable:    selects which bytes are active 
--  i_read:         start read cycle
--  i_write:        start write cycle
--  o_waitrequest:  when active stalls the transfer
--  i_writedata:    data to write
--  o_readdata:     data read
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
      g_addr_start  : integer;
      g_addr_stop   : integer;
      g_init_file   : string;
      g_trace_file  : string;
      g_wait_states : integer
    );
    port (
      i_clk         : in  std_logic;
      i_address     : in  std_logic_vector(29 downto 0);
      i_bytenable   : in  std_logic_vector(3 downto 0);
      i_read        : in  std_logic;
      i_write       : in  std_logic;
      o_waitrequest : out std_logic;
      i_writedata   : in  std_logic_vector(31 downto 0);
      o_readdata    : out std_logic_vector(31 downto 0)
    );
end entity avalon_bus;


architecture behave of avalon_bus is

  -- Internal memory
  type t_Memory is array (0 to (g_addr_stop - g_addr_start) / 4) of std_logic_vector(31 downto 0);
  signal memory : t_Memory := (others=>(others=>'0'));

  signal w_read_wait  : std_logic;
  signal w_write_wait : std_logic;
  signal w_addr       : integer;

begin

  w_addr        <= to_integer(unsigned(i_address)) - g_addr_start / 4;
  o_waitrequest <= w_read_wait or w_write_wait;


  -- Handle read request from bus
  p_read : process (i_clk, i_read, w_addr)
  begin
    w_read_wait <= '0';

    if (i_read = '1') then
      assert ((w_addr >= 0) and (w_addr < memory'length))
        report "Read out of bounds: addr=" & to_hstring(std_logic_vector(to_unsigned(w_addr*4+g_addr_start, 32)))
        severity failure;

      o_readdata <= memory(w_addr);
    end if;

  end process p_read;


  -- Handle write request from bus
  p_write : process (i_clk, i_write, w_addr)
    variable  v_init          : boolean := true;
    file      v_trace_file    : text;
    variable  v_trace_status  : file_open_status;
    file      v_init_file     : text;
    variable  v_init_status   : file_open_status;
    variable  v_line          : line;
    variable  v_addr          : integer := 0;
    variable  v_data          : std_logic_vector(31 downto 0);
  begin

    
    if(v_init) then
      v_init := false;

      -- Initialize memory content
      if (g_init_file /= "") then
        file_open(v_init_status, v_init_file, g_init_file, READ_MODE);
        assert (v_init_status = OPEN_OK) report "Unable to open input file: " & g_init_file severity failure;
  
        while (not endfile(v_init_file)) loop
          readline(v_init_file, v_line);
  
          assert v_addr <= g_addr_stop - g_addr_start report "To many items in input file" severity failure;
          hread(v_line, v_data);
          memory(v_addr) <= v_data;
          v_addr := v_addr + 1;
        end loop;
      end if;

      -- Open trace file
      if (g_trace_file /= "") then
        file_open(v_trace_status, v_trace_file, g_trace_file, WRITE_MODE);
        assert (v_trace_status = OPEN_OK) report "Unable to open trace file: " & g_trace_file severity failure;
      end if;
    end if;

    w_write_wait <= '0';

    if rising_edge(i_clk) then
      if (i_write = '1' and w_write_wait = '0') then
        assert ((w_addr >= 0) and (w_addr < memory'length))
          report "Write out of bounds: addr=" & to_hstring(std_logic_vector(to_unsigned(w_addr*4+g_addr_start, 32))) & " data=" &  to_hstring(i_writedata)
          severity failure;

        memory(w_addr)( 7 downto  0) <= i_writedata( 7 downto  0) when i_bytenable(0) = '1' else memory(w_addr)( 7 downto  0);
        memory(w_addr)(15 downto  8) <= i_writedata(15 downto  8) when i_bytenable(1) = '1' else memory(w_addr)(15 downto  8);
        memory(w_addr)(23 downto 16) <= i_writedata(23 downto 16) when i_bytenable(2) = '1' else memory(w_addr)(23 downto 16);
        memory(w_addr)(31 downto 24) <= i_writedata(31 downto 24) when i_bytenable(3) = '1' else memory(w_addr)(31 downto 24);

        -- Write trace file
        if (v_trace_status = OPEN_OK) then
          write(v_line, to_hstring(std_logic_vector(to_unsigned(w_addr*4+g_addr_start, 32))), right, 8);
          write(v_line, string'(": "), right, 2);
          write(v_line, to_hstring(i_writedata), right, 8);
          write(v_line, string'(" byteenable: "), right, 2);
          write(v_line, i_bytenable, right, 4);
          writeline(v_trace_file, v_line);
        end if;

      end if;
    end if;

  end process p_write;

  
end architecture behave;