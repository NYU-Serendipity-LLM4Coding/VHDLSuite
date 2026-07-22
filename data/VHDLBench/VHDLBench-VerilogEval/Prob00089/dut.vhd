-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 2's Complement Moore FSM with asynchronous reset

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk    : in  std_logic;
    areset : in  std_logic;
    x      : in  std_logic;
    z      : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  type state_type is (A, B, C);
  signal state : state_type;
  
begin
  
  process(clk, areset)
  begin
    if areset = '1' then
      state <= A;
    elsif rising_edge(clk) then
      case state is
        when A =>
          if x = '1' then
            state <= C;
          else
            state <= A;
          end if;
          
        when B =>
          if x = '1' then
            state <= B;
          else
            state <= C;
          end if;
          
        when C =>
          if x = '1' then
            state <= B;
          else
            state <= C;
          end if;
      end case;
    end if;
  end process;
  
  z <= '1' when state = C else '0';

end architecture rtl;