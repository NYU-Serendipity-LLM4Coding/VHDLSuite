-- (3) Reference implementation (RefModule)
-- Reference Module: Moore State Machine (Combinational Logic)
-- State encoding: A=00, B=01, C=10, D=11
-- Implements state transition logic and output logic
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out'

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    signal_in  : in  std_logic;
    state      : in  std_logic_vector(1 downto 0);
    next_state : out std_logic_vector(1 downto 0);
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding constants (matches Verilog parameters)
  constant A : std_logic_vector(1 downto 0) := "00";
  constant B : std_logic_vector(1 downto 0) := "01";
  constant C : std_logic_vector(1 downto 0) := "10";
  constant D : std_logic_vector(1 downto 0) := "11";
  
begin
  
  -- Matches Verilog: always_comb begin case (state) ... endcase end
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
        next_state <= A;  -- Default case for safety
    end case;
  end process;
  
  -- Matches Verilog: assign out = (state==D);
  -- Output logic
  signal_out <= '1' when state = D else '0';

end architecture rtl;