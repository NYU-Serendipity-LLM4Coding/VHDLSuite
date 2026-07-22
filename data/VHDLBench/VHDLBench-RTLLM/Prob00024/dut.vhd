-- (2) DUT implementation (TopModule)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm is
  port (
    IN_p  : in  std_logic;  -- Renamed from IN to avoid reserved keyword
    CLK   : in  std_logic;
    RST   : in  std_logic;
    MATCH : out std_logic
  );
end entity fsm;

architecture rtl of fsm is
  -- State encoding
  type state_t is (s0, s1, s2, s3, s4, s5);
  signal ST_cr, ST_nt : state_t;
  
begin

  -- State register process
  state_reg_proc : process(CLK, RST)
  begin
    if RST = '1' then
      ST_cr <= s0;
    elsif rising_edge(CLK) then
      ST_cr <= ST_nt;
    end if;
  end process;
  
  -- Next state logic (combinational)
  next_state_proc : process(ST_cr, IN_p)
  begin
    case ST_cr is
      when s0 =>
        if IN_p = '0' then
          ST_nt <= s0;
        else
          ST_nt <= s1;
        end if;
        
      when s1 =>
        if IN_p = '0' then
          ST_nt <= s2;
        else
          ST_nt <= s1;
        end if;
        
      when s2 =>
        if IN_p = '0' then
          ST_nt <= s3;
        else
          ST_nt <= s1;
        end if;
        
      when s3 =>
        if IN_p = '0' then
          ST_nt <= s0;
        else
          ST_nt <= s4;
        end if;
        
      when s4 =>
        if IN_p = '0' then
          ST_nt <= s2;
        else
          ST_nt <= s5;
        end if;
        
      when s5 =>
        if IN_p = '0' then
          ST_nt <= s2;
        else
          ST_nt <= s1;
        end if;
        
      when others =>
        ST_nt <= s0;
    end case;
  end process;
  
  -- Output logic (Mealy - combinational based on current state and input)
  output_proc : process(RST, ST_cr, IN_p)
  begin
    if RST = '1' then
      MATCH <= '0';
    elsif ST_cr = s4 and IN_p = '1' then
      MATCH <= '1';
    else
      MATCH <= '0';
    end if;
  end process;
  
end architecture rtl;