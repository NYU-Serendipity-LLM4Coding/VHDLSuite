-- (3) Reference implementation (RefModule)
-- Reference Module: 2's Complementer Mealy Machine
-- Two states: A (0) and B (1)
-- Asynchronous active-high reset to state A
-- Mealy machine output based on current state and input

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk    : in  std_logic;
    areset : in  std_logic;
    x      : in  std_logic;
    z      : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  -- State encoding (matches Verilog parameters)
  constant A : std_logic := '0';
  constant B : std_logic := '1';
  
  signal state : std_logic := A;
  
begin
  
  -- State transition process
  -- Matches Verilog: always @(posedge clk, posedge areset)
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
  
  -- Output logic (Mealy machine - depends on state and input)
  -- Matches Verilog: assign z = (state == A && x==1) | (state == B && x==0);
  z <= '1' when (state = A and x = '1') or (state = B and x = '0') else '0';

end architecture rtl;