-- (3) Reference implementation (RefModule)
-- Reference Module: Moore FSM with 4 states
-- State encoding: A=0, B=1, C=2, D=3
-- Asynchronous reset to state A
-- Output = 1 only in state D
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out'

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk        : in  std_logic;
    signal_in  : in  std_logic;
    areset     : in  std_logic;
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding (matches Verilog parameters)
  constant A : unsigned(1 downto 0) := "00";  -- 0
  constant B : unsigned(1 downto 0) := "01";  -- 1
  constant C : unsigned(1 downto 0) := "10";  -- 2
  constant D : unsigned(1 downto 0) := "11";  -- 3
  
  signal state : unsigned(1 downto 0) := A;
  signal next_state : unsigned(1 downto 0);
  
begin
  
  -- Next state logic (combinational)
  -- Matches Verilog: always_comb begin case (state) ... endcase end
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
  -- Matches Verilog: always @(posedge clk, posedge areset)
  state_register : process(clk, areset)
  begin
    if areset = '1' then
      state <= A;
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;
  
  -- Output logic (Moore machine: output depends only on state)
  -- Matches Verilog: assign out = (state==D);
  signal_out <= '1' when (state = D) else '0';

end architecture rtl;