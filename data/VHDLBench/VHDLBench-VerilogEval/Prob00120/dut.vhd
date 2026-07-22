-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Moore FSM with state transition table as described

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk        : in  std_logic;
    signal_in  : in  std_logic;
    reset      : in  std_logic;
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  -- State encoding
  constant A : std_logic_vector(1 downto 0) := "00";
  constant B : std_logic_vector(1 downto 0) := "01";
  constant C : std_logic_vector(1 downto 0) := "10";
  constant D : std_logic_vector(1 downto 0) := "11";
  
  signal state : std_logic_vector(1 downto 0) := A;
  signal next_state : std_logic_vector(1 downto 0);
  
begin
  
  -- Next state logic
  process(state, signal_in)
  begin
    case state is
      when A =>
        if signal_in = '1' then
          next_state <= B;
        else
          next_state <= A;
        end if;
        
      when B =>
        if signal_in = '1' then
          next_state <= B;
        else
          next_state <= C;
        end if;
        
      when C =>
        if signal_in = '1' then
          next_state <= D;
        else
          next_state <= A;
        end if;
        
      when D =>
        if signal_in = '1' then
          next_state <= B;
        else
          next_state <= C;
        end if;
        
      when others =>
        next_state <= A;
    end case;
  end process;
  
  -- State register
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= A;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  -- Output logic
  signal_out <= '1' when state = D else '0';

end architecture rtl;