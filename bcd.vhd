library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- http://www.eng.utah.edu/~nmcdonal/Tutorials/BCDTutorial/BCDConversion.html
-- 32 bits (10 digits): 253 ALM, 33.5ns
-- 24 bits ( 8 digits): 249 ALM, 31.9ns
-- 20 bits ( 7 digits): 235 ALM, 28.5ns
-- 16 bits ( 5 digits):  53 ALM, 15.2ns
entity bcd is
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
end entity bcd;
-----------------------------------
architecture a of bcd is
begin
  process(in_binary)
    variable s_digit_0 : unsigned( 3 downto 0);
    variable s_digit_1 : unsigned( 3 downto 0);
    variable s_digit_2 : unsigned( 3 downto 0);
    variable s_digit_3 : unsigned( 3 downto 0);
    variable s_digit_4 : unsigned( 3 downto 0);
    variable s_digit_5 : unsigned( 3 downto 0);
    variable s_digit_6 : unsigned( 3 downto 0);
    variable s_digit_7 : unsigned( 3 downto 0);
    variable s_digit_8 : unsigned( 3 downto 0);
    variable s_digit_9 : unsigned( 3 downto 0);
  begin
    s_digit_9 := "0000";
    s_digit_8 := "0000";
    s_digit_7 := "0000";
    s_digit_6 := "0000";
    s_digit_5 := "0000";
    s_digit_4 := "0000";
    s_digit_3 := "0000";
    s_digit_2 := "0000";
    s_digit_1 := "0000";
    s_digit_0 := "0000";

    for i in 31 downto 0 loop
      if (s_digit_9 >= 5) then s_digit_9 := s_digit_9 + 3; end if;
      if (s_digit_8 >= 5) then s_digit_8 := s_digit_8 + 3; end if;
      if (s_digit_7 >= 5) then s_digit_7 := s_digit_7 + 3; end if;
      if (s_digit_6 >= 5) then s_digit_6 := s_digit_6 + 3; end if;
      if (s_digit_5 >= 5) then s_digit_5 := s_digit_5 + 3; end if;
      if (s_digit_4 >= 5) then s_digit_4 := s_digit_4 + 3; end if;
      if (s_digit_3 >= 5) then s_digit_3 := s_digit_3 + 3; end if;
      if (s_digit_2 >= 5) then s_digit_2 := s_digit_2 + 3; end if;
      if (s_digit_1 >= 5) then s_digit_1 := s_digit_1 + 3; end if;
      if (s_digit_0 >= 5) then s_digit_0 := s_digit_0 + 3; end if;
      s_digit_9 := s_digit_9 sll 1; s_digit_9(0) := s_digit_8(3);
      s_digit_8 := s_digit_8 sll 1; s_digit_8(0) := s_digit_7(3);
      s_digit_7 := s_digit_7 sll 1; s_digit_7(0) := s_digit_6(3);
      s_digit_6 := s_digit_6 sll 1; s_digit_6(0) := s_digit_5(3);
      s_digit_5 := s_digit_5 sll 1; s_digit_5(0) := s_digit_4(3);
      s_digit_4 := s_digit_4 sll 1; s_digit_4(0) := s_digit_3(3);
      s_digit_3 := s_digit_3 sll 1; s_digit_3(0) := s_digit_2(3);
      s_digit_2 := s_digit_2 sll 1; s_digit_2(0) := s_digit_1(3);
      s_digit_1 := s_digit_1 sll 1; s_digit_1(0) := s_digit_0(3);
      s_digit_0 := s_digit_0 sll 1; s_digit_0(0) := in_binary(i);
    end loop;

    digit_0 <=  std_logic_vector(s_digit_0);
    digit_1 <=  std_logic_vector(s_digit_1);
    digit_2 <=  std_logic_vector(s_digit_2);
    digit_3 <=  std_logic_vector(s_digit_3);
    digit_4 <=  std_logic_vector(s_digit_4);
    digit_5 <=  std_logic_vector(s_digit_5);
    digit_6 <=  std_logic_vector(s_digit_6);
    digit_7 <=  std_logic_vector(s_digit_7);
    digit_8 <=  std_logic_vector(s_digit_8);
    digit_9 <=  std_logic_vector(s_digit_9);
  end process;

end architecture a;
