-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement Moore state machine combinational logic

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    signal_in  : in  std_logic;
    state      : in  std_logic_vector(1 downto 0);
    next_state : out std_logic_vector(1 downto 0);
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  -- State encoding constants
  constant A : std_logic_vector(1 downto 0) := "00";
  constant B : std_logic_vector(1 downto 0) := "01";
  constant C : std_logic_vector(1 downto 0) := "10";
  constant D : std_logic_vector(1 downto 0) := "11";
  
begin
  
  -- State transition logic
  process(signal_in, state)
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
  
  -- Output logic
  signal_out <= '1' when state = D else '0';

end architecture rtl;