-- *********************************************************************
-- file: stereo_dac.vhd
-- 
-- PCM Stereo DAC:
-- Uses Pulse Code Modulation to generate a bit pattern that after
-- low-pass filtering rappresents the analog value
--
-- Memory mAApped Inteface:
-- offset                 data
--   0   |  [31:16]=left_sample [15:0]=right_sample
--   4   |  [31:16]=clock_div   [15:0]=available
--
--  left_sample, right_sample: 
--    read:   undefined
--    write:  puts a new left/right audio sample in the FIFO, must be written together
--
--  clock_div: (sample_rate = FREQUENCY(i_clk) / clock_div)
--    read:   returns clock_div
--    write:  updates clock_div
--
--  available: (available slots in the FIFO)
--    read:   returns available slots in the FIFO
--    write:  no action
--
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity stereo_dac is
  port (
    i_clk           : in  std_logic;
    av_acknowledge  : out std_logic;
    av_irq          : out std_logic;
    av_address      : in  std_logic_vector(2 downto 0);
    av_bus_enable   : in  std_logic;
    av_byte_enable  : in  std_logic_vector(3 downto 0);
    av_rw           : in  std_logic;
    av_write_data   : in  std_logic_vector(31 downto 0);
    av_read_data    : out std_logic_vector(31 downto 0);
    o_left          : out std_logic;
    o_right         : out std_logic
  );
end entity stereo_dac;


architecture behave of stereo_dac is

  constant DAC_RES    : integer := 12;  -- Number of bits
  constant FIFO_BW    : integer := 6;
  constant FIFO_SIZE  : integer := 2**FIFO_BW;  -- Number of slots in the FIFO

  signal r_clock_div_ctr : unsigned(15 downto 0) := to_unsigned(0, 16);
  signal r_pcm_counter   : unsigned(DAC_RES-1 downto 0) := to_unsigned(0, DAC_RES);
  signal w_rev_counter   : unsigned(DAC_RES-1 downto 0);
  signal r_left_sample   : unsigned(DAC_RES-1 downto 0) := to_unsigned(0, DAC_RES);
  signal r_right_sample  : unsigned(DAC_RES-1 downto 0) := to_unsigned(0, DAC_RES);

  -- FIFO
  signal w_available      : unsigned(FIFO_BW-1 downto 0);
  signal w_fifo_full      : std_logic;
  signal w_fifo_empty     : std_logic;
  signal r_fifo_write_ptr : unsigned(FIFO_BW-1 downto 0) := to_unsigned(0, FIFO_BW);
  signal r_fifo_read_ptr  : unsigned(FIFO_BW-1 downto 0) := to_unsigned(0, FIFO_BW);
  type t_Memory is array (0 to FIFO_SIZE-1) of std_logic_vector(31 downto 0);
  signal memory : t_Memory;

  -- Memory mapped registers
  signal r_clock_div  : unsigned(15 downto 0) := to_unsigned(0, 16);

  -- Reverse bit order
  function reverse (a: in unsigned) return unsigned is
    variable result: unsigned(a'RANGE);
    alias aa: unsigned(a'REVERSE_RANGE) is a;
  begin
    for i in aa'RANGE loop
      result(i) := aa(i);
    end loop;
    return result;
  end;

begin

  -- Compute number of FIFO available slots
  w_available   <= to_unsigned(FIFO_SIZE - (to_integer(r_fifo_write_ptr) - to_integer(r_fifo_read_ptr)) - 1, w_available'LENGTH);
  w_fifo_full   <= '1' when (to_integer(w_available) = 0)            else '0';
  w_fifo_empty  <= '1' when (to_integer(w_available) = FIFO_SIZE-1)  else '0';

  -- Handle Avalon writes
  p_avalon : process (i_clk)
  begin
    if rising_edge(i_clk) then
      av_acknowledge <= '0'; 

      if (av_bus_enable = '1' and av_rw = '1' and av_acknowledge = '0') then       -- Read transaction
        av_acknowledge <= '1';

        case (av_address) is
          when "000" =>
            null;
          when "100" =>
            av_read_data(w_available'LENGTH-1 downto  0)  <= std_logic_vector(w_available);
            av_read_data(15 downto  w_available'LENGTH)   <= (others=>'0');

            av_read_data(31 downto 16)  <= std_logic_vector(r_clock_div);
          when others =>
            null;
        end case;
      elsif (av_bus_enable = '1' and av_rw = '0' and av_acknowledge = '0') then  -- Write transaction
        av_acknowledge <= '1';

        case (av_address) is
          when "000" =>
            -- Write to FIFO if not full
            if (w_fifo_full = '0') then
              memory(to_integer(r_fifo_write_ptr)) <= av_write_data;
              r_fifo_write_ptr <= r_fifo_write_ptr + 1;
            end if;

          when "100" =>
				    r_clock_div  <= unsigned(av_write_data(31 downto 16));
          when others =>
            null;
        end case;
      end if;

    end if;
  end process p_avalon;

  av_irq <= '0';


  -- Read from FIFO
  p_fifo_read : process (i_clk)
  begin
    if rising_edge(i_clk) then
      if (r_clock_div_ctr = r_clock_div) then
        -- Read from FIFO if not empty
        if (w_fifo_empty = '0') then
          r_right_sample  <= unsigned(memory(to_integer(r_fifo_read_ptr))(15 downto 15 - (DAC_RES-1)));
          r_left_sample   <= unsigned(memory(to_integer(r_fifo_read_ptr))(31 downto 31 - (DAC_RES-1)));
          r_fifo_read_ptr <= r_fifo_read_ptr + 1;
        end if;
        r_clock_div_ctr <= to_unsigned(0, r_clock_div_ctr'LENGTH);
      else
        r_clock_div_ctr <= r_clock_div_ctr + 1;
      end if;
    end if;
  end process p_fifo_read;

  -- Generate Pulse Code Modulation
  p_counter : process (i_clk)
  begin
    if rising_edge(i_clk) then
      r_pcm_counter <= r_pcm_counter + 1;
    end if;
  end process p_counter;

  w_rev_counter <= reverse(r_pcm_counter);
  o_left        <= '1' when (r_left_sample  <= w_rev_counter) else '0';
  o_right       <= '1' when (r_right_sample <= w_rev_counter) else '0';

end;