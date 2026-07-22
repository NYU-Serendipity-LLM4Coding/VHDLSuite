-- (3) Reference implementation (RefModule)
-- Reference Module: Motor Control FSM
-- State machine with 9 states (A, B, S0, S1, S10, G1, G2, P0, P1)
-- Outputs: f=1 for one cycle after reset, g monitors x/y patterns

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk    : in  std_logic;
    resetn : in  std_logic;
    x      : in  std_logic;
    y      : in  std_logic;
    f      : out std_logic;
    g      : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding (matches Verilog parameter)
  type state_type is (A, B, S0, S1, S10, G1, G2, P0, P1);
  signal state, next_state : state_type;
  
begin
  
  -----------------------------------------------------------------------------
  -- State register
  -- Matches Verilog: always @(posedge clk)
  -----------------------------------------------------------------------------
  state_reg : process(clk)
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        state <= A;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Next state logic
  -- Matches Verilog: always_comb
  -----------------------------------------------------------------------------
  next_state_logic : process(state, x, y)
  begin
    case state is
      when A =>
        next_state <= B;
        
      when B =>
        next_state <= S0;
        
      when S0 =>
        if x = '1' then
          next_state <= S1;
        else
          next_state <= S0;
        end if;
        
      when S1 =>
        if x = '1' then
          next_state <= S1;
        else
          next_state <= S10;
        end if;
        
      when S10 =>
        if x = '1' then
          next_state <= G1;
        else
          next_state <= S0;
        end if;
        
      when G1 =>
        if y = '1' then
          next_state <= P1;
        else
          next_state <= G2;
        end if;
        
      when G2 =>
        if y = '1' then
          next_state <= P1;
        else
          next_state <= P0;
        end if;
        
      when P0 =>
        next_state <= P0;
        
      when P1 =>
        next_state <= P1;
        
      when others =>
        next_state <= A;  -- Safe default
    end case;
  end process;
  
  -----------------------------------------------------------------------------
  -- Output logic
  -- Matches Verilog: assign f = (state == B);
  --                  assign g = (state == G1) || (state == G2) || (state == P1);
  -----------------------------------------------------------------------------
  f <= '1' when state = B else '0';
  g <= '1' when (state = G1 or state = G2 or state = P1) else '0';

end architecture rtl;