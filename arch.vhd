------------------------------------------------------------------------------
-- $Id: arch.vhd,v 1.33 2014/05/16 05:34:42 Stan Exp Stan $
-- Find prime numbers
-- Todo: #Primes per second
-- Todo: extend range to greater than 32 bits
------------------------------------------------------------------------------
library ieee; 
use ieee.numeric_std.all;
use work.sieve_pack.NUMBER_OF_DIVISORS;
architecture prime_finder of C5G is
  -- Aliases for the Arduino LCD Shield. Pins are shared with GPIO header
  alias lcd_db4 : std_logic is GPIO( 7);  -- (Arduino D4 ) Data Bit 4
  alias lcd_db5 : std_logic is GPIO( 8);  -- (Arduino D5 ) Data Bit 5
  alias lcd_db6 : std_logic is GPIO( 9);  -- (Arduino D6 ) Data Bit 6
  alias lcd_db7 : std_logic is GPIO(10);  -- (Arduino D7 ) Data Bit 7
  alias lcd_rs  : std_logic is GPIO(11);  -- (Arduino D8 ) RS (Data or Signal Display)
  alias lcd_en  : std_logic is GPIO(12);  -- (Arduino D9 ) Enable
  alias lcd_bl  : std_logic is GPIO(13);  -- (Arduino D10) Backlight Control

  -- Define 8 discrete inputs for 9-position rotary switch
  alias rotsw_p            : std_logic_vector              is GPIO(20 downto 17);  -- GPIO(18 downto 3) is Arduino(15 downto 0)
  alias led_prime_found    : std_logic                     is GPIO(21);
  alias divisible_flag_out : std_logic_vector(13 downto 0) is GPIO(35 downto 22);

  signal s_divisible_flag: std_logic_vector(0 to NUMBER_OF_DIVISORS-1);  -- A "divisible" flag for each of the prime counters

  signal N                 : unsigned (31 downto 0);
  signal latest_prime      : unsigned (31 downto 0);
  signal previous_prime    : unsigned (31 downto 0);
  signal prime_gap         : unsigned (31 downto 0);
  signal max_prime_gap     : unsigned (31 downto 0);

  signal digits_out        : std_logic_vector (15 downto 0);
  signal reset_n           : std_logic;
  signal button_next_prime : std_logic;
  signal next_prime        : boolean;
  signal button_next_n     : std_logic;
  signal next_n            : boolean;
  signal prime_found       : std_logic;
  signal runstop           : boolean;
  signal runstop_control   : boolean;
  signal display_pc        : boolean;  -- Display latest prime and candidate
  signal rotsw             : std_logic_vector(rotsw_p'range);

  -- LCD Sequencer
  type t_lcd_seq_state is (sa,sb,sc,sd,s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15,s16,
       s17,s18,s18_1,s18_2,s18_3,s19,s20,s21,s22,s23,s24,s25,s26,s27,s28,s29,s30,s31,s31_1,s32,s33,s34,
       s49,s50,s51,s52,s53,s54,s55,s56,s57,s58,s59,s60,s61,s62,s63,s64,s65);
  signal lcd_seq_state : t_lcd_seq_state;
  signal lcd_seq_nibble: std_logic;
  signal lcd_seq_data  : std_logic_vector(7 downto 0);
  signal lcd_seq_rs    : std_logic;
  signal lcd_seq_start : std_logic;
  signal lcd_seq_startlong : std_logic;
  signal lcd_seq_done  : std_logic;

  -- LCD opcodes for 44780
  constant OP_CLEAR       : std_logic_vector(7 downto 0) := "00000001";
  constant OP_HOME        : std_logic_vector(7 downto 0) := "00000010";
  constant OP_ENTRY_MODE  : std_logic_vector(7 downto 0) := "00000110"; -- auto-increment
  constant OP_ON          : std_logic_vector(7 downto 0) := "00001100"; -- display on, no cursor
  constant OP_CURSOR_L    : std_logic_vector(7 downto 0) := "00010000"; -- move cursor to left 
  constant OP_CURSOR_R    : std_logic_vector(7 downto 0) := "00010100";
  constant OP_CURSOR_L0   : std_logic_vector(7 downto 0) := "01000100";
  constant OP_FUNC_SET    : std_logic_vector(7 downto 0) := "00101000"; -- 2 lines
  constant OP_INIT        : std_logic_vector(7 downto 0) := "00110000"; -- Initializing by Instruction
  constant OP_NOP         : std_logic_vector(7 downto 0) := "00000000"; -- Placeholder
  constant OP_LINE1       : std_logic_vector(7 downto 0) := "10000000"; -- Go to top line
  constant OP_LINE2       : std_logic_vector(7 downto 0) := "11000000"; -- Go to second line
  constant LITERAL_COMMA  : std_logic_vector(7 downto 0) := "00101100"; -- ASCII 2C is comma
  constant LITERAL_SPACE  : std_logic_vector(7 downto 0) := "00100000"; -- ASCII 20 is space

  signal clock_core       : std_logic;

  -- bcd version of prime, for decimal-radix display on LED's and LCD
  signal bcd_0   : std_logic_vector(3 downto 0);
  signal bcd_1   : std_logic_vector(3 downto 0);
  signal bcd_2   : std_logic_vector(3 downto 0);
  signal bcd_3   : std_logic_vector(3 downto 0);
  signal bcd_4   : std_logic_vector(3 downto 0);
  signal bcd_5   : std_logic_vector(3 downto 0);
  signal bcd_6   : std_logic_vector(3 downto 0);
  signal bcd_7   : std_logic_vector(3 downto 0);
  signal bcd_8   : std_logic_vector(3 downto 0);
  signal bcd_9   : std_logic_vector(3 downto 0);

  signal bcd_n_0   : std_logic_vector(3 downto 0);
  signal bcd_n_1   : std_logic_vector(3 downto 0);
  signal bcd_n_2   : std_logic_vector(3 downto 0);
  signal bcd_n_3   : std_logic_vector(3 downto 0);
  signal bcd_n_4   : std_logic_vector(3 downto 0);
  signal bcd_n_5   : std_logic_vector(3 downto 0);
  signal bcd_n_6   : std_logic_vector(3 downto 0);
  signal bcd_n_7   : std_logic_vector(3 downto 0);
  signal bcd_n_8   : std_logic_vector(3 downto 0);
  signal bcd_n_9   : std_logic_vector(3 downto 0);

  signal num_primes         : std_logic_vector(31 downto 0); -- BCD module takes 32b
  signal bcd_num_primes_0   : std_logic_vector( 3 downto 0);
  signal bcd_num_primes_1   : std_logic_vector( 3 downto 0);
  signal bcd_num_primes_2   : std_logic_vector( 3 downto 0);
  signal bcd_num_primes_3   : std_logic_vector( 3 downto 0);
  signal bcd_num_primes_4   : std_logic_vector( 3 downto 0);
  signal bcd_num_primes_5   : std_logic_vector( 3 downto 0);
  signal bcd_num_primes_6   : std_logic_vector( 3 downto 0);
  signal bcd_num_primes_7   : std_logic_vector( 3 downto 0);
  signal bcd_num_primes_8   : std_logic_vector( 3 downto 0);

  signal bcd_mpg_0 : std_logic_vector( 3 downto 0);
  signal bcd_mpg_1 : std_logic_vector( 3 downto 0);
  signal bcd_mpg_2 : std_logic_vector( 3 downto 0);

  signal s_lcd_db7 : std_logic;
  signal s_lcd_db6 : std_logic;
  signal s_lcd_db5 : std_logic;
  signal s_lcd_db4 : std_logic;
  signal s_lcd_data: std_logic_vector(3 downto 0);
  signal s_lcd_rs  : std_logic;
  signal s_lcd_en  : std_logic;

  component button_debouncer
    port (
      clk     :  in std_logic;
      data_in :  in std_logic;
      data_out: out std_logic
    );
  end component;

  component rotsw_debounce
    port (
      clk     :  in std_logic;
      data_in :  in std_logic_vector(3 downto 0);
      data_out: out std_logic_vector(3 downto 0)
    );
  end component;

  component bcd 
    port (
      in_binary :  in std_logic_vector(31 downto 0);
      digit_0   : out std_logic_vector( 3 downto 0);
      digit_1   : out std_logic_vector( 3 downto 0);
      digit_2   : out std_logic_vector( 3 downto 0);
      digit_3   : out std_logic_vector( 3 downto 0);
      digit_4   : out std_logic_vector( 3 downto 0);
      digit_5   : out std_logic_vector( 3 downto 0);
      digit_6   : out std_logic_vector( 3 downto 0);
      digit_7   : out std_logic_vector( 3 downto 0);
      digit_8   : out std_logic_vector( 3 downto 0);
      digit_9   : out std_logic_vector( 3 downto 0)
    );
  end component ;

  component lcd_control 
    port (
      -- Tell this component what you want to write, then pulse start. 
      -- Done = finished and ready for another
      nibble   :  in std_logic;
      data     :  in std_logic_vector(7 downto 0);
      rs       :  in std_logic;
      start    :  in std_logic;
      startlong:  in std_logic;
      done     : out std_logic;

      -- LCD output
      lcd_data : out std_logic_vector(7 downto 4);
      lcd_rs   : out std_logic;
      lcd_en   : out std_logic;

      -- clock, reset
      clock    :  in std_logic;
      reset_n  :  in std_logic
    );
  end component;
  
  component sieve
    port (
      prime_found    : out std_logic;
      prime_number   : out unsigned(31 downto 0);
      N              : out unsigned(31 downto 0);
      divisible_flag : out std_logic_vector(0 to NUMBER_OF_DIVISORS-1);
      runstop        :  in boolean;
      clock_50_b5b   :  in std_logic;
      reset_n        :  in std_logic
    );
  end component;
begin
  -----------------------------------------------------------------------------
  -- This FSM configures LCD then continually updates the prime number display.
  lcd_sequencer : process (clock_core)
  begin
      if rising_edge (clock_core) then
        if reset_n = '0' then
          lcd_seq_state     <= sa;
          lcd_seq_start     <= '0';
          lcd_seq_startlong <= '0';
          lcd_seq_nibble    <= '0';
        else
          -- pulse lcd_seq_start at the start of each state entry.
          lcd_seq_start     <= '0';  -- Default. Pulse when entering a state, then return to 0
          lcd_seq_startlong <= '0';  -- Default. Pulse when entering a state, then return to 0
          lcd_seq_nibble    <= '0';  -- Default. Pulse when entering a state, then return to 0
          case lcd_seq_state is
            -- Reset sequence for LCD Controller 44780 is instruction 0x3- three times, one long and 2 short.
            when   sa => if reset_n = '1'      then lcd_seq_state <=  sb; lcd_seq_startlong <= '1'; end if;
            when   sb => if lcd_seq_done = '1' then lcd_seq_state <=  sc; lcd_seq_start <= '1';lcd_seq_nibble <= '1'; end if;
            when   sc => if lcd_seq_done = '1' then lcd_seq_state <=  sd; lcd_seq_start <= '1';lcd_seq_nibble <= '1'; end if;
            when   sd => if lcd_seq_done = '1' then lcd_seq_state <=  s0; lcd_seq_start <= '1';lcd_seq_nibble <= '1'; end if;

            -- When coming out of reset, s0->s1 happens unconditionally. Pulse "start" 
            when   s0 => lcd_seq_state <=  s1; lcd_seq_start <= '1'; lcd_seq_nibble <= '1';
            when   s1 => if lcd_seq_done = '1' then lcd_seq_state <=  s2; lcd_seq_start <= '1'; end if;  -- PON Initialization
            when   s2 => if lcd_seq_done = '1' then lcd_seq_state <=  s3; lcd_seq_start <= '1'; end if;
            when   s3 => if lcd_seq_done = '1' then lcd_seq_state <=  s4; lcd_seq_start <= '1'; end if;
            when   s4 => if lcd_seq_done = '1' then lcd_seq_state <=  s5; lcd_seq_start <= '1'; end if;
            when   s5 => if lcd_seq_done = '1' then lcd_seq_state <=  s6; lcd_seq_start <= '1'; end if;  -- Loop Start
            when   s6 => if lcd_seq_done = '1' then lcd_seq_state <=  s7; lcd_seq_start <= '1'; end if;
            when   s7 => if lcd_seq_done = '1' then lcd_seq_state <=  s8; lcd_seq_start <= '1'; end if;
            when   s8 => if lcd_seq_done = '1' then lcd_seq_state <=  s9; lcd_seq_start <= '1'; end if;
            when   s9 => if lcd_seq_done = '1' then lcd_seq_state <= s10; lcd_seq_start <= '1'; end if;
            when  s10 => if lcd_seq_done = '1' then lcd_seq_state <= s11; lcd_seq_start <= '1'; end if;
            when  s11 => if lcd_seq_done = '1' then lcd_seq_state <= s12; lcd_seq_start <= '1'; end if;
            when  s12 => if lcd_seq_done = '1' then lcd_seq_state <= s13; lcd_seq_start <= '1'; end if;
            when  s13 => if lcd_seq_done = '1' then lcd_seq_state <= s14; lcd_seq_start <= '1'; end if;
            when  s14 => if lcd_seq_done = '1' then lcd_seq_state <= s15; lcd_seq_start <= '1'; end if;
            when  s15 => if lcd_seq_done = '1' then lcd_seq_state <= s16; lcd_seq_start <= '1'; end if;
            when  s16 => if lcd_seq_done = '1' then lcd_seq_state <= s17; lcd_seq_start <= '1'; end if;
            when  s17 => if lcd_seq_done = '1' then lcd_seq_state <= s18; lcd_seq_start <= '1'; end if;
            when  s18 => if lcd_seq_done = '1' then lcd_seq_state <= s18_1; lcd_seq_start <= '1'; end if;

            -- hacky workaround to LCD initialization problem, crumbs are left-over on 3 rightmost chars
            when  s18_1 => if lcd_seq_done = '1' then lcd_seq_state <= s18_2; lcd_seq_start <= '1'; end if;
            when  s18_2 => if lcd_seq_done = '1' then lcd_seq_state <= s18_3; lcd_seq_start <= '1'; end if;

            -- Choose what to draw on second line
            when  s18_3 => 
              if lcd_seq_done = '1' then 
                if display_pc then  -- Display Prime and Candidate
                  lcd_seq_state <= s49; 
                else -- Display latest Prime, Ordinality of latest Prime, Max Prime Gap
                  lcd_seq_state <= s19; 
                end if;
                lcd_seq_start <= '1'; 
              end if;

            -- Second Line: Ordinality, Max Prime Gap
            when  s19 => if lcd_seq_done = '1' then lcd_seq_state <= s20; lcd_seq_start <= '1'; end if;
            when  s20 => if lcd_seq_done = '1' then lcd_seq_state <= s21; lcd_seq_start <= '1'; end if;
            when  s21 => if lcd_seq_done = '1' then lcd_seq_state <= s22; lcd_seq_start <= '1'; end if;
            when  s22 => if lcd_seq_done = '1' then lcd_seq_state <= s23; lcd_seq_start <= '1'; end if;
            when  s23 => if lcd_seq_done = '1' then lcd_seq_state <= s24; lcd_seq_start <= '1'; end if;
            when  s24 => if lcd_seq_done = '1' then lcd_seq_state <= s25; lcd_seq_start <= '1'; end if;
            when  s25 => if lcd_seq_done = '1' then lcd_seq_state <= s26; lcd_seq_start <= '1'; end if;
            when  s26 => if lcd_seq_done = '1' then lcd_seq_state <= s27; lcd_seq_start <= '1'; end if;
            when  s27 => if lcd_seq_done = '1' then lcd_seq_state <= s28; lcd_seq_start <= '1'; end if;
            when  s28 => if lcd_seq_done = '1' then lcd_seq_state <= s29; lcd_seq_start <= '1'; end if;
            when  s29 => if lcd_seq_done = '1' then lcd_seq_state <= s30; lcd_seq_start <= '1'; end if;
            when  s30 => if lcd_seq_done = '1' then lcd_seq_state <= s31; lcd_seq_start <= '1'; end if;
            when  s31 => if lcd_seq_done = '1' then lcd_seq_state <= s31_1; lcd_seq_start <= '1'; end if;
            when  s31_1 => if lcd_seq_done = '1' then lcd_seq_state <= s32; lcd_seq_start <= '1'; end if;
            when  s32 => if lcd_seq_done = '1' then lcd_seq_state <= s33; lcd_seq_start <= '1'; end if;
            when  s33 => if lcd_seq_done = '1' then lcd_seq_state <= s34; lcd_seq_start <= '1'; end if;
            when  s34 => if lcd_seq_done = '1' then lcd_seq_state <=  s5; lcd_seq_start <= '1'; end if;

            when  s49 => if lcd_seq_done = '1' then lcd_seq_state <= s50; lcd_seq_start <= '1'; end if;
            when  s50 => if lcd_seq_done = '1' then lcd_seq_state <= s51; lcd_seq_start <= '1'; end if;
            when  s51 => if lcd_seq_done = '1' then lcd_seq_state <= s52; lcd_seq_start <= '1'; end if;
            when  s52 => if lcd_seq_done = '1' then lcd_seq_state <= s53; lcd_seq_start <= '1'; end if;
            when  s53 => if lcd_seq_done = '1' then lcd_seq_state <= s54; lcd_seq_start <= '1'; end if;
            when  s54 => if lcd_seq_done = '1' then lcd_seq_state <= s55; lcd_seq_start <= '1'; end if;
            when  s55 => if lcd_seq_done = '1' then lcd_seq_state <= s56; lcd_seq_start <= '1'; end if;
            when  s56 => if lcd_seq_done = '1' then lcd_seq_state <= s57; lcd_seq_start <= '1'; end if;
            when  s57 => if lcd_seq_done = '1' then lcd_seq_state <= s58; lcd_seq_start <= '1'; end if;
            when  s58 => if lcd_seq_done = '1' then lcd_seq_state <= s59; lcd_seq_start <= '1'; end if;
            when  s59 => if lcd_seq_done = '1' then lcd_seq_state <= s60; lcd_seq_start <= '1'; end if;
            when  s60 => if lcd_seq_done = '1' then lcd_seq_state <= s61; lcd_seq_start <= '1'; end if;
            when  s61 => if lcd_seq_done = '1' then lcd_seq_state <= s62; lcd_seq_start <= '1'; end if;
            when  s62 => if lcd_seq_done = '1' then lcd_seq_state <= s63; lcd_seq_start <= '1'; end if;
            when  s63 => if lcd_seq_done = '1' then lcd_seq_state <= s64; lcd_seq_start <= '1'; end if;
            when  s64 => if lcd_seq_done = '1' then lcd_seq_state <= s65; lcd_seq_start <= '1'; end if;
            when  s65 => if lcd_seq_done = '1' then lcd_seq_state <=  s5; lcd_seq_start <= '1'; end if;



          end case;
        end if;  -- not reset
      end if;  -- rising_edge(clock_core)
  end process lcd_sequencer;

  -- Mux for data to LCD.  Data Sources:
  --   bcd            = Prime Number. 10-digit (to 4 billion)
  --   bcd_num_primes = running count of number of primes found. 7 digits (to 2 Million)
  --   bcd_mpg        = Maximum Prime Gap found. 3 digits (to 360)
  process(lcd_seq_state, 
           bcd_9,bcd_8,bcd_7,bcd_6,bcd_5,bcd_4,bcd_3,bcd_2,bcd_1,bcd_0,
           bcd_n_9,bcd_n_8,bcd_n_7,bcd_n_6,bcd_n_5,bcd_n_4,bcd_n_3,bcd_n_2,bcd_n_1,bcd_n_0,
           bcd_num_primes_8,bcd_num_primes_7,bcd_num_primes_6,bcd_num_primes_5,bcd_num_primes_4,bcd_num_primes_3,bcd_num_primes_2,bcd_num_primes_1,bcd_num_primes_0,
           bcd_mpg_2,bcd_mpg_1,bcd_mpg_0
         )
  begin
    case lcd_seq_state is

      -- Initializing by Instruction" : 3 opwords with long, short, short timeouts
      when  sa => lcd_seq_rs <= '0'; lcd_seq_data <= OP_INIT;
      when  sb => lcd_seq_rs <= '0'; lcd_seq_data <= OP_INIT;
      when  sc => lcd_seq_rs <= '0'; lcd_seq_data <= OP_INIT;
      when  sd => lcd_seq_rs <= '0'; lcd_seq_data <= OP_INIT;
      --          0=instr, 1=data      ascii numerals are 3x
      when  s0 => lcd_seq_rs <= '0'; lcd_seq_data <= OP_FUNC_SET;    -- No-op: no "start" pulse til s1
      when  s1 => lcd_seq_rs <= '0'; lcd_seq_data <= OP_FUNC_SET;    -- S1 is a 1-nibble operation
      when  s2 => lcd_seq_rs <= '0'; lcd_seq_data <= OP_FUNC_SET;    -- Full 2-nibble transfer
      when  s3 => lcd_seq_rs <= '0'; lcd_seq_data <= OP_ON;          -- Turn on Display, hide cursor no blink
      when  s4 => lcd_seq_rs <= '0'; lcd_seq_data <= OP_ENTRY_MODE;  -- auto-increment ddram
      -- 0x3n is ASCII for digit 0-9
      when  s5 => lcd_seq_rs <= '0'; lcd_seq_data <= OP_LINE1;       -- return cursor to origin
      when  s6 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_9;  
      when  s7 => lcd_seq_rs <= '1'; lcd_seq_data <= LITERAL_COMMA;
      when  s8 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_8;
      when  s9 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_7;
      when s10 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_6;
      when s11 => lcd_seq_rs <= '1'; lcd_seq_data <= LITERAL_COMMA;
      when s12 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_5;
      when s13 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_4;
      when s14 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_3;
      when s15 => lcd_seq_rs <= '1'; lcd_seq_data <= LITERAL_COMMA;
      when s16 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_2;
      when s17 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_1;
      when s18 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_0;
      when s18_1 => lcd_seq_rs <= '1'; lcd_seq_data <= LITERAL_SPACE;
      when s18_2 => lcd_seq_rs <= '1'; lcd_seq_data <= LITERAL_SPACE;
      when s18_3 => lcd_seq_rs <= '1'; lcd_seq_data <= LITERAL_SPACE;

      when s19 => lcd_seq_rs <= '0'; lcd_seq_data <= OP_LINE2;
      when s20 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_num_primes_8;
      when s21 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_num_primes_7;
      when s22 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_num_primes_6;
      when s23 => lcd_seq_rs <= '1'; lcd_seq_data <= LITERAL_COMMA;
      when s24 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_num_primes_5;
      when s25 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_num_primes_4;
      when s26 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_num_primes_3;
      when s27 => lcd_seq_rs <= '1'; lcd_seq_data <= LITERAL_COMMA;
      when s28 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_num_primes_2;
      when s29 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_num_primes_1;
      when s30 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_num_primes_0;
      when s31 => lcd_seq_rs <= '1'; lcd_seq_data <= LITERAL_SPACE;
      when s31_1 => lcd_seq_rs <= '1'; lcd_seq_data <= LITERAL_SPACE;
      when s32 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_mpg_2;
      when s33 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_mpg_1;
      when s34 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_mpg_0;
      
      when s49 => lcd_seq_rs <= '0'; lcd_seq_data <= OP_LINE2;
      when s50 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_n_9;
      when s51 => lcd_seq_rs <= '1'; lcd_seq_data <= LITERAL_COMMA;
      when s52 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_n_8;
      when s53 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_n_7; 
      when s54 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_n_6;
      when s55 => lcd_seq_rs <= '1'; lcd_seq_data <= LITERAL_COMMA;
      when s56 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_n_5;
      when s57 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_n_4; 
      when s58 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_n_3; 
      when s59 => lcd_seq_rs <= '1'; lcd_seq_data <= LITERAL_COMMA;
      when s60 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_n_2;
      when s61 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_n_1;
      when s62 => lcd_seq_rs <= '1'; lcd_seq_data <= "0011" & bcd_n_0;
      when s63 => lcd_seq_rs <= '1'; lcd_seq_data <= LITERAL_SPACE;
      when s64 => lcd_seq_rs <= '1'; lcd_seq_data <= LITERAL_SPACE;
      when s65 => lcd_seq_rs <= '1'; lcd_seq_data <= LITERAL_SPACE;

    end case;
  end process;

  -----------------------------------------------------------------------------
  -- Low-level LCD controller.
  -- Input is nibble-level control signals.
  -- DFRobot Arduino shield has a 6-signal interface which does not allow 
  -- for 44780 polling. So LCD sequencer has to wait for worst case.
  -- Apparently Arduino is slower so polling is not required.
  -- LCD basic operation times seem to be around 38uS.
  u_lcd_control : lcd_control
    port map (
      nibble   => lcd_seq_nibble,
      data     => lcd_seq_data,
      rs       => lcd_seq_rs,
      start    => lcd_seq_start,
      startlong=> lcd_seq_startlong,
      done     => lcd_seq_done,

      lcd_data => s_lcd_data,
      lcd_rs   => s_lcd_rs,
      lcd_en   => s_lcd_en,

      clock    => clock_core,
      reset_n  => reset_n
    );

  (s_lcd_db7, s_lcd_db6, s_lcd_db5, s_lcd_db4) <= s_lcd_data;

  lcd_db7 <= s_lcd_db7;
  lcd_db6 <= s_lcd_db6;
  lcd_db5 <= s_lcd_db5;
  lcd_db4 <= s_lcd_db4;
  lcd_rs  <= s_lcd_rs;
  lcd_en  <= s_lcd_en;
  -----------------------------------------------------------------------------
  -- Maximal Prime Gap recorder.
  previous_prime_reg: process(clock_core)
  begin
    if rising_edge(clock_core) then 
      if (reset_n = '0') then
        --previous_prime <= (others => '0');
        previous_prime <= to_unsigned(1, 32); 
      elsif (prime_found = '1') then
        previous_prime <= latest_prime;
      end if;
    end if;
  end process;

  prime_gap <= latest_prime - previous_prime;

  max_prime_gap_reg : process(clock_core)
  begin
    if rising_edge(clock_core) then
      if reset_n = '0' then
        max_prime_gap <= (others => '0');
      elsif prime_found = '1' then
        if prime_gap > max_prime_gap then
          max_prime_gap <= prime_gap;
        end if;
      end if;
    end if;
  end process;

  -- Switches and buttons
  ledr <= sw; -- Just cuz they're purty
  ledg(7) <= not key(3);
  ledg(5) <= not key(2);
  ledg(3) <= not key(1);
  ledg(1) <= not key(0);

  -----------------------------------------------------------------------------
  clock_core <= clock_50_B5B;

  -------------------------
  -- Button 0 = Reset
  u_debounce_0: button_debouncer  
    port map (
      clk      => clock_core,
      data_in  => key(0),
      data_out => reset_n
    );
  -------------------------
  -- Button 1 = Find next prime
  u_debounce_1: button_debouncer  
    port map (
      clk      => clock_core,
      data_in  => key(1),
      data_out => button_next_prime
    );
  -------------------------
  -- Button 2 = Advance to next N
  u_debounce_2: button_debouncer  
    port map (
      clk      => clock_core,
      data_in  => key(2),
      data_out => button_next_n
    );
  -------------------------
  -- Rotary Switch = speed
  u_rotsw_debounce: rotsw_debounce
    port map (
      clk      => clock_core,
      data_in  => rotsw_p,
      data_out => rotsw
    );
  ------------------------------- 
  -- Metastability protection, slide switch
  dispmode_conditioner : process(clock_core)
    variable display_pc_p : boolean;
  begin
    if rising_edge(clock_core) then
      display_pc    <= display_pc_p;
      display_pc_p := (sw(0) = '1');  -- careful with ordering! want a flop infered
    end if;
  end process dispmode_conditioner;
  ------------------------------- 
  -- one-shot next N
  next_N_edge_detect : process (clock_core)
    variable button_next_n_d : std_logic;
  begin
    if rising_edge (clock_core) then
      next_N <= ( button_next_n_d = '0' and button_next_n = '1');
      button_next_n_d := button_next_n;
    end if;
  end process next_N_edge_detect;
  ------------------------------- 
  -- one-shot "next prime" button
  next_prime_edge_detect : process (clock_core)
    variable button_next_prime_d : std_logic;
  begin
    if rising_edge (clock_core) then
      if prime_found='1' then -- Reset next_prime to FALSE
        next_prime <= FALSE;  -- Prime found, end of this search
      else 
        if ( button_next_prime_d = '0' and button_next_prime = '1') then -- latch next_prime to TRUE
          next_prime <= TRUE;
        end if;
        button_next_prime_d := button_next_prime;
      end if;
    end if;
  end process next_prime_edge_detect;
  ------------------------------- 
  -- Rotary Switch controls "runstop_control" pwm
  -- Four speeds possible: Stopped (for single step operation), 1 hz, 1/1000th full speed and full speed. 
  runstop_control_proc : process (clock_core)
    constant PWM_WIDTH    : natural := 25352365;  -- 5 hz is 50,000,000 hz / 10,000,000. Random to miss beats
    variable count : natural range 0 to PWM_WIDTH;
  begin
    if rising_edge (clock_core) then
      if reset_n = '0' then
        count := 0;
      else
        count := count + 1;
        case rotsw is
          when "0111"  => runstop_control <= next_n or next_prime;     -- Stop, except if "next N" pressed or we're searching for next prime
          when "1011"  => runstop_control <= (count=1);  -- Run one count per pwm width
          when "1101"  => runstop_control <= (count < PWM_WIDTH * 10/1000);  -- Duty Cycle over PWM period
          when "1110"  => runstop_control <= true;       -- Full Speed
          when others  => runstop_control <= false;       -- For debounce, it would be nice to not count
        end case;
        if count = PWM_WIDTH then 
          count := 0;
        end if;
      end if;
    end if;
  end process runstop_control_proc; 

  -- A mess. Need to async decode "next_prime and prime_found" and drive runstop false so sieve stops immediately.
  runstop <= runstop_control and not (prime_found='1' and next_prime);

  -- This is the prime number sieve itself, implemented as a subcomponent
  u_sieve: sieve
    port map (
      prime_found    => prime_found,
      prime_number   => latest_prime,  -- up to a point!
      N              => N,
      divisible_flag => s_divisible_flag,
      runstop        => runstop,
      clock_50_b5b   => clock_core,
      reset_n        => reset_n
    );

  -- Drive disrete LED's with divisibility of first 14 primes. 
  -- Common Anode configuration means we need to invert 
  -- The rest of the unused flags will be swept away during logic optimization
  divisible_flag_out <= not s_divisible_flag(0 to 13); 

  ------------------------------- 
  -- Prime Counter
  ------------------------------- 
  u_prime_counter : process (clock_core)
  begin
    if rising_edge(clock_core) then
      if reset_n = '0' then
        num_primes <= std_logic_vector(to_unsigned(0,32));
      elsif( prime_found = '1' and runstop ) then
        num_primes <= std_logic_vector(unsigned(num_primes) + 1);
      end if;
    end if;
  end process;
  ------------------------------- 
  u_bcd_mpg: bcd
    port map (
      in_binary => std_logic_vector(max_prime_gap),
      digit_0   => bcd_mpg_0,
      digit_1   => bcd_mpg_1,
      digit_2   => bcd_mpg_2,
      digit_3   => OPEN,
      digit_4   => OPEN,
      digit_5   => OPEN,
      digit_6   => OPEN,
      digit_7   => OPEN,
      digit_8   => OPEN,
      digit_9   => OPEN
    ); 
  ------------------------------- 
  u_bcd_num_primes: bcd
    port map (
      in_binary => num_primes,
      digit_0   => bcd_num_primes_0,
      digit_1   => bcd_num_primes_1,
      digit_2   => bcd_num_primes_2,
      digit_3   => bcd_num_primes_3,
      digit_4   => bcd_num_primes_4,
      digit_5   => bcd_num_primes_5,
      digit_6   => bcd_num_primes_6,
      digit_7   => bcd_num_primes_7,
      digit_8   => bcd_num_primes_8,
      digit_9   => OPEN
    ); 
  ------------------------------- 
  u_bcd_n: bcd
    port map (
      in_binary => std_logic_vector(N(31 downto 0)),
      digit_0   => bcd_n_0,
      digit_1   => bcd_n_1,
      digit_2   => bcd_n_2,
      digit_3   => bcd_n_3,
      digit_4   => bcd_n_4,
      digit_5   => bcd_n_5,
      digit_6   => bcd_n_6,
      digit_7   => bcd_n_7,
      digit_8   => bcd_n_8,
      digit_9   => bcd_n_9
    ); 

  ------------------------------- 
  u_bcd: bcd
    port map (
      in_binary => std_logic_vector(latest_prime(31 downto 0)),
      digit_0   => bcd_0,
      digit_1   => bcd_1,
      digit_2   => bcd_2,
      digit_3   => bcd_3,
      digit_4   => bcd_4,
      digit_5   => bcd_5,
      digit_6   => bcd_6,
      digit_7   => bcd_7,
      digit_8   => bcd_8,
      digit_9   => bcd_9
    ); 

  -- Turn off all LED segments (hex2, hex3 are repurposed as GPIO)
  hex0 <= (others => '1');
  hex1 <= (others => '1');
  led_prime_found <= not prime_found; -- Common Anode LED so invert 

end architecture prime_finder;
