-- *********************************************************************
-- file: hpc.vhd
-- 
-- Hardware Performance Counter:
-- multiple counters to measure CPU events.
-- Couters are read and reset via a memory mappped interface
--
-- Memory Mapped Inteface:
-- offset                 data
--   0   |  [3]=snapshot [2]=clear [1]=stop [0]=start
--   4   |  [31:0]=clock_cnt_l
--   8   |  [31:0]=clock_cnt_h
--  12   |  [31:0]=instr_cnt_l
--  16   |  [31:0]=instr_cnt_h
--  20   |  [31:0]=fetch_cnt_l
--  24   |  [31:0]=fetch_cnt_h
--  28   |  [31:0]=execute_cnt_l
--  32   |  [31:0]=execute_cnt_h
--  36   |  [31:0]=memory_cnt_l
--  40   |  [31:0]=memory_cnt_h
--
--  snapshot: 
--    read:   undefined
--    write:  takes a snapshot of the register values so that they can be read coherently
--  clear: 
--    read:   undefined
--    write:  clears the registers
--  stop: 
--    read:   undefined
--    write:  keeps the counters from updating
--  start: 
--    read:   undefined
--    write:  makes the counters update
--
--  clock_cnt_h, clock_cnt_l: high and low clock conters, increments every clock cycle
--    read:   returns clock_cnt_h/clock_cnt_l
--    write:  no action
--
--  instr_cnt_h, instr_cnt_l: high and low instruction conters, increments every instruction
--    read:   returns instr_cnt_h/instr_cnt_l
--    write:  no action
--
--  fetch_cnt_h, fetch_cnt_l: high and low instruction conters, increments every instruction
--    read:   returns fetch_cnt_h/fetch_cnt_l
--    write:  no action
--
--  execute_cnt_h, execute_cnt_l: high and low instruction conters, increments every instruction
--    read:   returns execute_cnt_h/execute_cnt_l
--    write:  no action
--
--  decode_cnt_h, decode_cnt_l: high and low instruction conters, increments every instruction
--    read:   returns decode_cnt_h/decode_cnt_l
--    write:  no action
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity hpc is
    port (
      i_clk               : in  std_logic;
      i_rst               : in  std_logic;
      -- Avalon memory mapped slave
      av_acknowledge      : out std_logic;
      av_irq              : out std_logic;
      av_address          : in  std_logic_vector(5 downto 0);
      av_bus_enable       : in  std_logic;
      av_byte_enable      : in  std_logic_vector(3 downto 0);
      av_rw               : in  std_logic;
      av_write_data       : in  std_logic_vector(31 downto 0);
      av_read_data        : out std_logic_vector(31 downto 0);
      -- CPU state
      i_cpu_debug_vector  : in  std_logic_vector(31 downto 0)
    );
  end entity hpc;


  architecture behave of hpc is
    signal w_start_req  : std_logic;
    signal w_stop_req   : std_logic;
    signal w_clear_req  : std_logic;
    signal w_snap_req   : std_logic;

    signal r_running    : std_logic := '0';
    signal r_clock_cnt  : unsigned(63 downto 0)         := (others=>'0');
    signal r_instr_cnt  : unsigned(63 downto 0)         := (others=>'0');
    signal r_fetch_cnt  : unsigned(63 downto 0)         := (others=>'0');
    signal r_execu_cnt  : unsigned(63 downto 0)         := (others=>'0');
    signal r_memry_cnt  : unsigned(63 downto 0)         := (others=>'0');
    signal r_clock_snp  : std_logic_vector(63 downto 0) := (others=>'0');
    signal r_instr_snp  : std_logic_vector(63 downto 0) := (others=>'0');
    signal r_fetch_snp  : std_logic_vector(63 downto 0) := (others=>'0');
    signal r_execu_snp  : std_logic_vector(63 downto 0) := (others=>'0');
    signal r_memry_snp  : std_logic_vector(63 downto 0) := (others=>'0');

    signal w_active   : std_logic;
    signal w_read     : std_logic;
    signal w_write    : std_logic;
    signal w_read_mux : std_logic_vector(31 downto 0);

    signal w_cpu_fetch      : std_logic;
    signal w_cpu_execu      : std_logic;
    signal w_cpu_memry      : std_logic;
    signal r_cpu_fetch0     : std_logic;
    signal w_cpu_fetch_rise : std_logic;
  begin

    -- Unpack debug vector
    w_cpu_fetch <= i_cpu_debug_vector(0);
    w_cpu_execu <= i_cpu_debug_vector(2);
    w_cpu_memry <= i_cpu_debug_vector(3);

    -- Handle Avalon buss
    av_irq <= '0';

    w_active  <= '1' when (av_bus_enable = '1' and av_acknowledge = '0')  else '0';
    w_read    <= '1' when (w_active = '1' and av_rw = '1')                else '0';
    w_write   <= '1' when (w_active = '1' and av_rw = '0')                else '0';

    w_read_mux <= r_clock_snp(31 downto  0) when (av_address = "000100") else
                  r_clock_snp(63 downto 32) when (av_address = "001000") else
                  r_instr_snp(31 downto  0) when (av_address = "001100") else
                  r_instr_snp(63 downto 32) when (av_address = "010000") else
                  r_fetch_snp(31 downto  0) when (av_address = "010100") else
                  r_fetch_snp(63 downto 32) when (av_address = "011000") else
                  r_execu_snp(31 downto  0) when (av_address = "011100") else
                  r_execu_snp(63 downto 32) when (av_address = "100000") else
                  r_memry_snp(31 downto  0) when (av_address = "100100") else
                  r_memry_snp(63 downto 32) when (av_address = "101000") else
                  (others=>'-');

    w_start_req <= '1' when (w_write = '1') and (av_address = "000000") and (av_write_data(0) = '1') else '0';
    w_stop_req  <= '1' when (w_write = '1') and (av_address = "000000") and (av_write_data(1) = '1') else '0';
    w_clear_req <= '1' when (w_write = '1') and (av_address = "000000") and (av_write_data(2) = '1') else '0';
    w_snap_req  <= '1' when (w_write = '1') and (av_address = "000000") and (av_write_data(3) = '1') else '0';

    p_avalon : process (i_clk)
    begin
      if rising_edge(i_clk) then
        av_acknowledge <= '0'; 

        -- Acknowledge transaction
        if (w_active = '1') then
          av_acknowledge <= '1';
        end if;

        -- Read transection
        if (w_read = '1') then
          av_read_data  <= w_read_mux;
        end if;

      end if;
    end process p_avalon;


    -- Update counters
    p_counters : process (i_clk)
    begin
      if rising_edge(i_clk) then
        if (i_rst = '1') then
          r_clock_cnt <= (others=>'0');
          r_instr_cnt <= (others=>'0');
          r_fetch_cnt <= (others=>'0');
          r_execu_cnt <= (others=>'0');
          r_memry_cnt <= (others=>'0');
          r_running   <= '0';
        else
          -- start/stop counters
          if (w_start_req = '1') then
            r_running <= '1';
          elsif (w_stop_req = '1') then
            r_running <= '0';
          end if;
          -- clear/update counters
          if (w_clear_req = '1') then
            r_clock_cnt <= (others=>'0');
            r_instr_cnt <= (others=>'0');
            r_fetch_cnt <= (others=>'0');
            r_execu_cnt <= (others=>'0');
            r_memry_cnt <= (others=>'0');
          elsif (r_running = '1') then
            if (w_cpu_fetch_rise = '1') then
              r_instr_cnt <= r_instr_cnt + 1;
            end if;
            if (w_cpu_fetch = '1') then
              r_fetch_cnt <= r_fetch_cnt + 1;
            end if;
            if (w_cpu_execu = '1') then
              r_execu_cnt <= r_execu_cnt + 1;
            end if;
            if (w_cpu_memry = '1') then
              r_memry_cnt <= r_memry_cnt + 1;
            end if;
            r_clock_cnt <= r_clock_cnt + 1;
          end if;
          -- take snapshot
          if (w_snap_req = '1') then
            r_clock_snp <= std_logic_vector(r_clock_cnt);
            r_instr_snp <= std_logic_vector(r_instr_cnt);
            r_fetch_snp <= std_logic_vector(r_fetch_cnt);
            r_execu_snp <= std_logic_vector(r_execu_cnt);
            r_memry_snp <= std_logic_vector(r_memry_cnt);
          end if;
        end if;
      end if;
    end process p_counters;


    -- Detect rising edge of cpu fetch signal
    w_cpu_fetch_rise <= '1' when (r_cpu_fetch0 = '0' and w_cpu_fetch = '1') else '0';
    p_fetch : process (i_clk)
    begin
      if rising_edge(i_clk) then
        r_cpu_fetch0 <= w_cpu_fetch;
      end if;
    end process p_fetch;

  end architecture behave;