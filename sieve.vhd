-------------------------------------------------------------------------------
-- Prime Number Sieve ("Sieve of Erastothenes")
-- Some outputs were added to accomodate lighting up external LED's, and 
-- providing information for Max Prime Gap tracker etc.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sieve_pack.all;

entity sieve is
  port (
    prime_found    : out std_logic;
    prime_number   : out unsigned(31 downto 0);
    N              : out unsigned(31 downto 0);
    divisible_flag : out std_logic_vector(0 to NUMBER_OF_DIVISORS-1);
    runstop        :  in boolean;
    clock_50_b5b   :  in std_logic;
    reset_n        :  in std_logic
  );
end entity;
-------------------------------------------------------------------------------
architecture a of sieve is
  -- Must stop at square of last sieve element
  constant MAX_N : integer := (SEED_PRIMES(NUMBER_OF_DIVISORS-2)) ** 2; 

  signal s_divisible_flag : std_logic_vector(0 to NUMBER_OF_DIVISORS-1) := (others => '0');
  signal s_N              : unsigned(31 downto 0) := (others => '0');
  signal s_prime_found    : std_logic := '0';
  signal prime_found_p    : std_logic := '0';
  signal prime_found_pp   : std_logic := '0';
  alias clock : std_logic is clock_50_b5b;
begin
  ----------------------------------
  gen_sieve_counters: for i in s_divisible_flag'range generate  
  begin
    process (clock)
      constant TC         : positive range 1 to SEED_PRIMES(i) := SEED_PRIMES(i);
      variable my_count   : positive range 1 to SEED_PRIMES(i) := 1;
      variable first_pass : boolean := true;
    begin
      if rising_edge(clock) then
        if (reset_n = '0') then
          my_count := 1; 
          s_divisible_flag(i) <= '0';  -- Reset value is 1 to turn off "prime found" flag
          first_pass := true;
        else
          if runstop and s_N < MAX_N then
            if (my_count = TC) then
               my_count := 1;
               s_divisible_flag(i) <= '0';
            else
               my_count := my_count + 1;
               if my_count = TC then
                 if first_pass then
                   s_divisible_flag(i) <= '0';  -- Suppress "divisible" output first time around
                 else
                   s_divisible_flag(i) <= '1';
                 end if;
                 first_pass := false;
               end if;
            end if;
          end if;
        end if;
      end if;
    end process;
  end generate gen_sieve_counters;
  ----------------------------------
  process (s_divisible_flag)
    variable big_or_temp : std_logic := '0';
  begin
    big_or_temp := '0';
    for i in s_divisible_flag'range loop
      big_or_temp := big_or_temp or s_divisible_flag(i);
    end loop;
    s_prime_found <= not big_or_temp;
  end process;
  ----------------------------------
  N_counter: process(clock)
  begin
    if rising_edge(clock) then
      if reset_n = '0' then
         s_N <= to_unsigned(1,32);  
      elsif runstop and s_N < MAX_N then
         s_N <= s_N + 1;
      end if;
    end if;
  end process;
  ----------------------------------
  prime_latch : process (clock)
  begin
    if rising_edge(clock) then
      if reset_n = '0' then
        prime_number <= to_unsigned(1,32);
      elsif s_prime_found = '1' then
        prime_number <= s_N;
      end if;     
    end if;
  end process;
  ----------------------------------
  N <= s_N;
  prime_found <= s_prime_found;
  divisible_flag <= s_divisible_flag;
end architecture a;
