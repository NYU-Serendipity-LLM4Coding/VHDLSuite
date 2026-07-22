-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 2's Complementer Mealy Machine with one-hot encoding

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
  -- State encoding (one-hot: only one bit is '1')
  constant A : std_logic := '0';
  constant B : std_logic := '1';
  
  signal state : std_logic := A;
  
begin
  
  -- State transition process with asynchronous reset
  process(clk, areset)
  begin
    if areset = '1' then
      state <= A;
    elsif rising_edge(clk) then
      case state is
        when A =>
          if x = '1' then
            state <= B;
          else
            state <= A;
          end if;
        when B =>
          state <= B;
        when others =>
          state <= A;
      end case;
    end if;
  end process;
  
  -- Mealy output: depends on current state and input
  z <= '1' when (state = A and x = '1') or (state = B and x = '0') else '0';

end architecture rtl;