-- Driver for Hitachi 44780 LCD controller and clones.
-- This is for driving the DFRobot Arduino LCD shield, which has a 4-bit interface
-- I never got the reset to work properly. 
-- The driving module must write every character in the 2x16 display otherwise there
-- are crumbs left behind when the LCD is reset.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity lcd_control is
  port (
    -- Slave interface
    nibble   :  in std_logic; -- Single-nibble transfer
    data     :  in std_logic_vector(7 downto 0);
    rs       :  in std_logic;
    start    :  in std_logic;  --  100 us timeout
    startlong:  in std_logic;  -- 4100 us timeout
    done     : out std_logic;

    -- LCD output
    lcd_data : out std_logic_vector(7 downto 4);
    lcd_rs   : out std_logic;
    lcd_en   : out std_logic;

    -- clock, reset
    clock    :  in std_logic;
    reset_n  :  in std_logic
    );
end entity lcd_control;

--------------------------------------------------------------------------------
--    _   _   _   _   _   _   _   _   _   _   _   _   _   _ 
--   / \_/0\_/1\_/2\_/3\_/4\_/5\
--      
--       
--  rs  _X___________________X__
--
--                _______       
--  en  _________/       \______
--
--        ___________________ __
-- data  X___________________X__
--
--
-- Address (wrt enable pulse) Tas = 40min; Tah =10min
-- Data (wrt trailing edge of en) Tdsw=80; Th=10
-- At 50Mhz (20ns cycle) this means 
--
--   Clock   T    Action
--     0     0    Apply data, rs
--     1    20    wait
--     2    40    assert enable (Tas=40)
--     3    60    wait
--     4    80    negate Enable (Tdsw=80)
--     5   100    Next Data, rs (Tah=20, Th=20)
--------------------------------------------------------------------------------
architecture a of lcd_control is
  type t_state is (srst, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s15, s16, s17, s18, s19, sa, sb, sc, sd, se );
  signal state : t_state;
  alias high_nibble : std_logic_vector(3 downto 0) is data(7 downto 4);
  alias low_nibble  : std_logic_vector(3 downto 0) is data(3 downto 0);
  constant terminal_count : integer := 10000;  
  constant terminal_reset_count : integer := 4100000/20;   -- Long timeout, 4.1 ms at 20ns clock cycle
  signal tc : std_logic;
  signal reset_tc : std_logic;
  signal start_wait_counter : boolean;
  signal start_long_counter : boolean;
begin
  lcd_rs <= rs; -- this signal doesn't really need to go through this component.

  ------------------------------------------- 
  -- wait 4100 us
  wait_4100 : process (clock)
    variable wait_count : unsigned(31 downto 0);
  begin
    if rising_edge(clock) then
      if reset_n='0' or start_long_counter then
         wait_count := (others => '0');
         reset_tc <= '0';
      elsif wait_count < terminal_reset_count then
         wait_count := wait_count + 1;
         reset_tc <= '0';
      else -- count = reset_tc 
         wait_count := (others => '0'); 
         reset_tc <= '1';
      end if;
    end if;
  end process;

  ------------------------------------------- 
  wait_lcd : process (clock)
    variable wait_count : unsigned(31 downto 0);
  begin
    if rising_edge(clock) then
      if reset_n='0' or start_wait_counter then
         wait_count := (others => '0');
         tc <= '0';
      elsif wait_count < terminal_count then
         wait_count := wait_count + 1;
         tc <= '0';
      else -- count = tc 
         wait_count := (others => '0'); 
         tc <= '1';
      end if;
    end if;
  end process;

  process(clock)
  begin
    if rising_edge(clock) then
      -- Default Values, to be overriden       
      done               <= '0';
      lcd_en             <= '0';
      start_wait_counter <= false;
      start_long_counter <= false;

      if (reset_n = '0') then
        lcd_data <= high_nibble;
        state      <= srst;
      else
        case state is
          -- Wait for "start" to write the numbers to the instruction/data word
          when srst =>
            if reset_n = '1' then 
              state <= s0; 
            end if;

          when s0 =>
            lcd_data <= high_nibble;              -- latch a starting value for deata
            if start = '1' and nibble = '0' then       -- Write two nibbles
              state    <= s1;
              lcd_data <= high_nibble;
            elsif start='1' and nibble = '1' then      -- write one nibbles
              state    <= s15;
              lcd_data <= low_nibble;
            elsif startlong='1' then                   -- Special-case write a reset nibble then wait long
              state    <= sa;
              lcd_data <= high_nibble;
            else
              state    <= s0;
              lcd_data <= high_nibble;
            end if;

          -- This branch is for a 2-nibble transfer (high, then low)
          when  s1 => lcd_data <= high_nibble; state <=  s2;lcd_en <= '1'; 
          when  s2 => lcd_data <= high_nibble; state <=  s3;lcd_en <= '1'; start_wait_counter <= true;
          when  s3 => lcd_data <= high_nibble; state <=  s4;
          when  s4 => lcd_data <= 
            low_nibble;  state <=  s5;
            if tc = '1' then 
              state <= s5; 
            else 
              state <= s4; 
            end if;
          when  s5 => lcd_data <= low_nibble;  state <=  s6;
          when  s6 => lcd_data <= low_nibble;  state <=  s7;lcd_en <= '1';
          when  s7 => lcd_data <= low_nibble;  state <=  s8;lcd_en <= '1'; start_wait_counter <= true;
          when  s8 => 
            lcd_data <= low_nibble;  
            if tc = '1' then 
              state <= s9; 
            else 
              state <= s8; 
            end if;
          when  s9 => lcd_data <= low_nibble;  state <=  s0;  done <= '1';            

          -- This branch is for a single nibble transfer (high nibble)
          when s15 => lcd_data <= high_nibble; state <= s16;
          when s16 => lcd_data <= high_nibble; state <= s17;lcd_en <= '1';
          when s17 => lcd_data <= high_nibble; state <= s18;lcd_en <= '1'; start_wait_counter <= true;
          when s18 => 
            lcd_data <= high_nibble; 
            if tc = '1' then 
              state <= s19; 
            else 
              state <= s18; 
            end if;
          when s19 => lcd_data <= high_nibble; state <= s0;     done <= '1'; 

          -- Transfer high nibble, followed by a long wait for "instruction initialize" sequence:
          --    Apply 0x3- with startlong
          --    Apply 0x3- with normal "start"
          --    Apply 0x3- with normal "start"
          -- 
          when sa  => lcd_data <= high_nibble; state <= sb;
          when sb  => lcd_data <= high_nibble; state <= sc;lcd_en <= '1';
          when sc  => lcd_data <= high_nibble; state <= sd;lcd_en <= '1'; start_long_counter <= true;
          when sd => 
            lcd_data <= high_nibble; 
            if reset_tc = '1' then 
              state <= se; 
            else 
              state <= sd; 
            end if;
          when se => lcd_data <= high_nibble; state <= s0;     done <= '1'; 


        end case;
      end if;
    end if;
  end process;
end architecture a;
