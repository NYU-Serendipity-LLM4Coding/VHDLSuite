-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Mealy FSM detecting "101" with async reset

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk     : in  std_logic;
    aresetn : in  std_logic;
    x       : in  std_logic;
    z       : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  -- State encoding
  constant S   : unsigned(1 downto 0) := "00";
  constant S1  : unsigned(1 downto 0) := "01";
  constant S10 : unsigned(1 downto 0) := "10";
  
  signal state : unsigned(1 downto 0) := S;
  signal next_state : unsigned(1 downto 0);
  
begin

  -- State register with asynchronous reset
  state_reg : process(clk, aresetn)
  begin
    if aresetn = '0' then
      state <= S;
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;
  
  -- Next state logic
  next_state_logic : process(state, x)
  begin
    case state is
      when "00" =>  -- S
        if x = '1' then
          next_state <= S1;
        else
          next_state <= S;
        end if;
        
      when "01" =>  -- S1
        if x = '1' then
          next_state <= S1;
        else
          next_state <= S10;
        end if;
        
      when "10" =>  -- S10
        if x = '1' then
          next_state <= S1;
        else
          next_state <= S;
        end if;
        
      when others =>
        next_state <= "XX";
    end case;
  end process;
  
  -- Output logic (Mealy)
  output_logic : process(state, x)
  begin
    case state is
      when "00" =>  -- S
        z <= '0';
        
      when "01" =>  -- S1
        z <= '0';
        
      when "10" =>  -- S10
        z <= x;
        
      when others =>
        z <= 'X';
    end case;
  end process;

end architecture rtl;