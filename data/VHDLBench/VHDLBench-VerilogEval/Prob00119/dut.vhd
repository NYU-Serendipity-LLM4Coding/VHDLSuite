-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Moore FSM with state table as specified

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk        : in  std_logic;
    signal_in  : in  std_logic;
    areset     : in  std_logic;
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  -- State encoding
  constant A : unsigned(1 downto 0) := "00";
  constant B : unsigned(1 downto 0) := "01";
  constant C : unsigned(1 downto 0) := "10";
  constant D : unsigned(1 downto 0) := "11";
  
  signal state : unsigned(1 downto 0) := A;
  signal next_state : unsigned(1 downto 0);
  
begin
  
  -- Next state logic
  next_state_logic : process(state, signal_in)
  begin
    case state is
      when "00" =>  -- State A
        if signal_in = '1' then
          next_state <= B;
        else
          next_state <= A;
        end if;
        
      when "01" =>  -- State B
        if signal_in = '1' then
          next_state <= B;
        else
          next_state <= C;
        end if;
        
      when "10" =>  -- State C
        if signal_in = '1' then
          next_state <= D;
        else
          next_state <= A;
        end if;
        
      when "11" =>  -- State D
        if signal_in = '1' then
          next_state <= B;
        else
          next_state <= C;
        end if;
        
      when others =>
        next_state <= A;
    end case;
  end process;
  
  -- State register with asynchronous reset
  state_register : process(clk, areset)
  begin
    if areset = '1' then
      state <= A;
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;
  
  -- Output logic
  signal_out <= '1' when (state = D) else '0';

end architecture rtl;