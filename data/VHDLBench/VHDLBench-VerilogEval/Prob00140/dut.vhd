-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: HDLC Framing FSM

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk       : in  std_logic;
    reset     : in  std_logic;
    signal_in : in  std_logic;
    disc      : out std_logic;
    flag      : out std_logic;
    err       : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  type state_t is (S0, S1, S2, S3, S4, S5, S6, SERR, SDISC, SFLAG);
  signal state : state_t := S0;
  
begin
  
  -- Moore FSM outputs
  disc <= '1' when state = SDISC else '0';
  flag <= '1' when state = SFLAG else '0';
  err  <= '1' when state = SERR  else '0';
  
  -- State machine
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= S0;
      else
        case state is
          when S0 =>
            if signal_in = '1' then
              state <= S1;
            else
              state <= S0;
            end if;
            
          when S1 =>
            if signal_in = '1' then
              state <= S2;
            else
              state <= S0;
            end if;
            
          when S2 =>
            if signal_in = '1' then
              state <= S3;
            else
              state <= S0;
            end if;
            
          when S3 =>
            if signal_in = '1' then
              state <= S4;
            else
              state <= S0;
            end if;
            
          when S4 =>
            if signal_in = '1' then
              state <= S5;
            else
              state <= S0;
            end if;
            
          when S5 =>
            if signal_in = '1' then
              state <= S6;
            else
              state <= SDISC;
            end if;
            
          when S6 =>
            if signal_in = '1' then
              state <= SERR;
            else
              state <= SFLAG;
            end if;
            
          when SERR =>
            if signal_in = '1' then
              state <= SERR;
            else
              state <= S0;
            end if;
            
          when SFLAG =>
            if signal_in = '1' then
              state <= S1;
            else
              state <= S0;
            end if;
            
          when SDISC =>
            if signal_in = '1' then
              state <= S1;
            else
              state <= S0;
            end if;
            
          when others =>
            state <= S0;
        end case;
      end if;
    end if;
  end process;

end architecture rtl;