-- (3) Reference implementation (RefModule)
-- Reference FSM with 6 states (A, B, C, D, E, F)
-- Output z is high when in states E or F
-- Synchronous active-high reset to state A

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    w     : in  std_logic;
    z     : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State enumeration (matches Verilog parameter A=0, B=1, etc.)
  type state_type is (A, B, C, D, E, F);
  signal state : state_type := A;
  signal next_state : state_type;
  
begin

  -- State register (matches Verilog: always @(posedge clk))
  -- Synchronous reset to state A
  state_register : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= A;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  -- Next state logic (matches Verilog: always_comb)
  next_state_logic : process(state, w)
  begin
    case state is
      when A =>
        if w = '1' then
          next_state <= B;
        else
          next_state <= A;
        end if;
        
      when B =>
        if w = '1' then
          next_state <= C;
        else
          next_state <= D;
        end if;
        
      when C =>
        if w = '1' then
          next_state <= E;
        else
          next_state <= D;
        end if;
        
      when D =>
        if w = '1' then
          next_state <= F;
        else
          next_state <= A;
        end if;
        
      when E =>
        if w = '1' then
          next_state <= E;
        else
          next_state <= D;
        end if;
        
      when F =>
        if w = '1' then
          next_state <= C;
        else
          next_state <= D;
        end if;
        
      when others =>
        next_state <= A;  -- Safe default
    end case;
  end process;
  
  -- Output logic (matches Verilog: assign z = (state == E) || (state == F))
  z <= '1' when (state = E or state = F) else '0';

end architecture rtl;