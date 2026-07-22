-- (3) Reference implementation (RefModule)
-- Reference Module: Moore FSM with 4 states
-- State transition table:
--   State | Next (in=0) | Next (in=1) | Output
--   A(00) | A           | B           | 0
--   B(01) | C           | B           | 0
--   C(10) | A           | D           | 0
--   D(11) | C           | B           | 1
-- Synchronous active-high reset to state A
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out'

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk        : in  std_logic;
    signal_in  : in  std_logic;
    reset      : in  std_logic;
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding (matches Verilog parameter A=0, B=1, C=2, D=3)
  constant A : std_logic_vector(1 downto 0) := "00";
  constant B : std_logic_vector(1 downto 0) := "01";
  constant C : std_logic_vector(1 downto 0) := "10";
  constant D : std_logic_vector(1 downto 0) := "11";
  
  signal state : std_logic_vector(1 downto 0) := A;
  signal next_state : std_logic_vector(1 downto 0);
  
begin
  
  -- Combinational next state logic
  -- Matches Verilog: always_comb begin case (state) ... endcase end
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
  
  -- State register with synchronous reset
  -- Matches Verilog: always @(posedge clk) begin if (reset) state <= A; else state <= next; end
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
  
  -- Output logic (Moore machine - output depends only on state)
  -- Matches Verilog: assign out = (state==D);
  signal_out <= '1' when state = D else '0';

end architecture rtl;