-- *********************************************************************
-- file: video_gen.vhd
-- 
-- VGA Video Generator:
-- Resolution 640x480@60 Hz (pixel clock 25.175 MHz)
--
--
-- Memory Mapped Inteface:
-- offset                 data
--   0   |  [31:0]=pixel_fifo_data
--   4   |  [17]=h_sync  [16]=v_sync  [15:0]=available
--   8   |  [11:8]=clk_div  [7:4]=h_div  [3:0]=v_div
--  12   |
--
--  pixel_fifo_data: 
--    read:   undefined
--    write:  puts 32 bits into the pixel fifo
--
--  h_sync: (horizontal sync flag)
--    read:   returns h_sync
--    write:  clears fifo
--
--  v_sync: (vertical sync flag)
--    read:   returns v_sync
--    write:  clears fifo
--
--  available: (available slots in the FIFO)
--    read:   returns available slots in the FIFO
--    write:  clears fifo
--
--  clk_div: (pixel_clk = FREQUENCY(i_clk) / clk_div)
--    read:   returns clk_div
--    write:  updates clk_div
--
--  h_div: (num_horizontal_pixels = 640 / h_div)
--    read:   returns h_div
--    write:  updates h_div
--
--  v_div: (num_vertical_pixels = 480 / v_div)
--    read:   returns v_div
--    write:  updates v_div
--
--
-- *********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity video_gen is
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
end entity video_gen;


architecture behave of video_gen is

  constant PIX_W        : integer := 640;
  constant PIX_H        : integer := 480;
  constant SCRN_W       : integer := 800;
  constant SCRN_H       : integer := 524;
  constant H_SYNC_START : integer := 656;
  constant H_SYNC_STOP  : integer := 752;
  constant V_SYNC_START : integer := 491;
  constant V_SYNC_STOP  : integer := 493;
  constant FIFO_BW      : integer := integer(ceil(log2(real(FIFO_SIZE))));

  -- timing generator
  signal r_ctr_c  : integer range 0 to 15 := 0; 
  signal r_ctr_x  : integer range 0 to SCRN_W-1 := 0;
  signal r_ctr_y  : integer range 0 to SCRN_H-1 := 0;
  signal w_ce     : std_logic;

  -- controll
  signal w_first_line       : std_logic;
  signal w_first_pixel      : std_logic;
  signal w_new_pixel        : std_logic;
  signal w_fifo_read        : std_logic;
  signal w_buffer_indx      : integer range 0 to PIX_W/32-1;
  signal w_mux_sel          : std_logic;
  signal w_shift_reg_reload : std_logic;
  signal w_shift_reg_en     : std_logic;
  signal w_blanking         : std_logic;
  signal w_h_sync           : std_logic;
  signal w_v_sync           : std_logic;
  signal w_v_sync_long      : std_logic;

  signal w_mux_out          : std_logic_vector(31 downto 0);
  signal r_shift_reg_data   : std_logic_vector(31 downto 0);
  signal w_shift_reg_out    : std_logic;

  signal r_h_sync_0     : std_logic;
  signal r_v_sync_0     : std_logic;
  signal r_blanking_0   : std_logic;

  -- Line buffer
  type t_line_bf is array (0 to PIX_W/32-1) of std_logic_vector(31 downto 0);
  signal m_line_bf : t_line_bf;

  -- FIFO
  signal w_available      : unsigned(FIFO_BW-1 downto 0);
  signal w_fifo_full      : std_logic;
  signal w_fifo_empty     : std_logic;
  signal r_fifo_write_ptr : unsigned(FIFO_BW-1 downto 0) := to_unsigned(0, FIFO_BW);
  signal r_fifo_read_ptr  : unsigned(FIFO_BW-1 downto 0) := to_unsigned(0, FIFO_BW);
  type t_fifo is array (0 to FIFO_SIZE-1) of std_logic_vector(31 downto 0);
  signal m_fifo : t_fifo;

  -- Memory mapped registers
  signal r_clk_div  : unsigned(3 downto 0) := to_unsigned(1, 4);
  signal r_h_div    : unsigned(3 downto 0) := to_unsigned(1, 4);
  signal r_v_div    : unsigned(3 downto 0) := to_unsigned(1, 4);

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
          when "0100" =>  --   4   |  [17]=h_sync  [16]=v_sync  [15:0]=available
            av_read_data(w_available'LENGTH-1 downto  0)  <= std_logic_vector(w_available);
            av_read_data(15 downto  w_available'LENGTH)   <= (others=>'0');

            av_read_data(16)  <= not w_v_sync_long;
            av_read_data(17)  <= not w_h_sync;
          when "1000" =>  --   8   |  [11:8]=clk_div  [7:4]=h_div  [3:0]=v_div
            av_read_data( 3 downto 0) <= std_logic_vector(r_v_div);
            av_read_data( 7 downto 4) <= std_logic_vector(r_h_div);
            av_read_data(11 downto 8) <= std_logic_vector(r_clk_div);
          when others =>
            null;
        end case;
      elsif (av_bus_enable = '1' and av_rw = '0' and av_acknowledge = '0') then  -- Write transaction
        av_acknowledge <= '1';

        case (av_address) is
          when "0000" =>--   0   |  [31:0]=pixel_fifo_data
            -- Write to FIFO if not full
            if (w_fifo_full = '0') then
              m_fifo(to_integer(r_fifo_write_ptr)) <= av_write_data;
              r_fifo_write_ptr <= r_fifo_write_ptr + 1;
            end if;
          when "0100" =>  --   4   |  [17]=h_sync  [16]=v_sync  [15:0]=available
            r_fifo_write_ptr <= r_fifo_read_ptr;  -- clear FIFO
          when "1000" =>  --   8   |  [11:8]=clk_div  [7:4]=h_div  [3:0]=v_div
            r_v_div   <= unsigned(av_write_data( 3 downto 0));
            r_h_div   <= unsigned(av_write_data( 7 downto 4));
				    r_clk_div <= unsigned(av_write_data(11 downto 8));
          when others =>
            null;
        end case;
      end if;

    end if;
  end process p_avalon;

  av_irq <= '0';



  -- Timing generator
  w_ce  <= '1' when (r_ctr_c = 0) else '0';

  p_timing_gen : process (i_clk)
  begin
    if rising_edge(i_clk) then
      -- increment clock counter
      if (r_ctr_c = to_integer(r_clk_div)) then
        r_ctr_c <= 0;

        if (r_ctr_x = SCRN_W-1) then
          r_ctr_x <= 0;

          if (r_ctr_y = SCRN_H-1) then
            r_ctr_y <= 0;
          else
            r_ctr_y <= r_ctr_y + 1;
          end if;
        else
          r_ctr_x <= r_ctr_x + 1;
        end if;
      else
        r_ctr_c <= r_ctr_c + 1;
      end if;
    end if;
  end process p_timing_gen;



  -- Controll
  w_blanking    <= '0' when (r_ctr_x < PIX_W) and (r_ctr_y < PIX_H)                 else '1';
  w_h_sync      <= '0' when (r_ctr_x >= H_SYNC_START) and (r_ctr_x < H_SYNC_STOP)   else '1';
  w_v_sync      <= '0' when (r_ctr_y >= V_SYNC_START) and (r_ctr_y < V_SYNC_STOP)   else '1';
  w_v_sync_long <= '0' when (r_ctr_y >= PIX_H)                                      else '1';

  w_first_line <= '1' when (r_v_div = "0001") and (r_ctr_y mod (1) = 0) else
                  '1' when (r_v_div = "0010") and (r_ctr_y mod (2) = 0) else
                  '1' when (r_v_div = "0100") and (r_ctr_y mod (4) = 0) else
                  '1' when (r_v_div = "1000") and (r_ctr_y mod (8) = 0) else '0';

  w_first_pixel <= '1' when (r_h_div = "0001") and (r_ctr_x mod (32*1) = 0) else
                   '1' when (r_h_div = "0010") and (r_ctr_x mod (32*2) = 0) else
                   '1' when (r_h_div = "0100") and (r_ctr_x mod (32*4) = 0) else
                   '1' when (r_h_div = "1000") and (r_ctr_x mod (32*8) = 0) else '0';

  w_new_pixel <= '1' when (r_h_div = "0001") and (r_ctr_x mod (1) = 0) else
                 '1' when (r_h_div = "0010") and (r_ctr_x mod (2) = 0) else
                 '1' when (r_h_div = "0100") and (r_ctr_x mod (4) = 0) else
                 '1' when (r_h_div = "1000") and (r_ctr_x mod (8) = 0) else '0';

  w_buffer_indx <= r_ctr_x/(32*1) when (r_h_div = "0001") else
                   r_ctr_x/(32*2) when (r_h_div = "0010") else
                   r_ctr_x/(32*4) when (r_h_div = "0100") else
                   r_ctr_x/(32*8) when (r_h_div = "1000") else 0;

  w_mux_sel <= w_first_line;

  p_control : process (w_ce, r_ctr_x, r_ctr_y, w_blanking, w_first_line, w_first_pixel, w_new_pixel)
  begin
    w_fifo_read         <= '0';
    w_shift_reg_reload  <= '0';
    w_shift_reg_en      <= '0';

    if (w_ce = '1') then
      -- FIFO read signal
      if (w_blanking = '0' and w_first_line = '1' and w_first_pixel = '1') then
        w_fifo_read <= '1';
      end if;
      -- shift reload signal
      if (w_blanking = '0' and w_first_pixel = '1') then
        w_shift_reg_reload  <= '1';
      end if;
      -- shift en signal
      if (w_blanking = '0' and w_new_pixel = '1') then
        w_shift_reg_en  <= '1';
      end if;
    end if;
  end process p_control;
  


  -- Video generator
  p_video : process (i_clk)
  begin
    if rising_edge(i_clk) then
      if (w_ce = '1') then
        -- delayed by one cycle
        r_h_sync_0    <= w_h_sync;
        r_v_sync_0    <= w_v_sync;
        r_blanking_0  <= w_blanking;

        o_vga_hs  <= r_h_sync_0;
        o_vga_vs  <= r_v_sync_0;

        if (r_blanking_0 = '1') then
          o_vga_r <= (others=>'0');
          o_vga_g <= (others=>'0');
          o_vga_b <= (others=>'0');
        else
          o_vga_r <= (others=>w_shift_reg_out);
          o_vga_g <= (others=>w_shift_reg_out);
          o_vga_b <= (others=>w_shift_reg_out);
        end if;
      end if;
    end if;
  end process p_video;


  -- Shift register
  w_shift_reg_out <= r_shift_reg_data(0);

  p_shift_reg : process (i_clk)
  begin
    if rising_edge(i_clk) then
      if (w_shift_reg_reload = '1') then
        r_shift_reg_data <= w_mux_out;
      elsif(w_shift_reg_en = '1') then
        r_shift_reg_data <= '-' & r_shift_reg_data(31 downto 1);
      end if;
    end if;
  end process p_shift_reg;

  

  -- Multiplexer
  w_mux_out     <= m_fifo(to_integer(r_fifo_read_ptr)) when (w_mux_sel = '1') else m_line_bf(w_buffer_indx);

  -- Read from FIFO
  p_fifo_read : process (i_clk)
  begin
    if rising_edge(i_clk) then
      if (w_fifo_read = '1') then
        -- Read from FIFO if not empty
        if (w_fifo_empty = '0') then
          m_line_bf(w_buffer_indx)  <= m_fifo(to_integer(r_fifo_read_ptr));
          r_fifo_read_ptr           <= r_fifo_read_ptr + 1;
        end if;
      end if;
    end if;
  end process p_fifo_read;

end;