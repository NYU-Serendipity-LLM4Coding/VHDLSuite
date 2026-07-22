-- (3) Reference implementation (RefModule)
-- Reference Module: FSM Arbiter with Priority
-- State machine with 4 states (A, B, C, D)
-- Priority: r(1) > r(2) > r(3)
-- Active-low synchronous reset to state A

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk    : in  std_logic;
    resetn : in  std_logic;
    r      : in  std_logic_vector(3 downto 1);
    g      : out std_logic_vector(3 downto 1)
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding (matches Verilog parameters)
  type state_type is (A, B, C, D);
  signal state, next_state : state_type;
  
begin

  -----------------------------------------------------------------------------
  -- State register (synchronous reset)
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
  -- Next state logic (combinational)
  -- Matches Verilog: always@(state,r)
  -----------------------------------------------------------------------------
  next_state_logic : process(state, r)
  begin
    case state is
      when A =>
        if r(1) = '1' then
          next_state <= B;
        elsif r(2) = '1' then
          next_state <= C;
        elsif r(3) = '1' then
          next_state <= D;
        else
          next_state <= A;
        end if;
        
      when B =>
        if r(1) = '1' then
          next_state <= B;
        else
          next_state <= A;
        end if;
        
      when C =>
        if r(2) = '1' then
          next_state <= C;
        else
          next_state <= A;
        end if;
        
      when D =>
        if r(3) = '1' then
          next_state <= D;
        else
          next_state <= A;
        end if;
        
      when others =>
        next_state <= A;  -- Default case
    end case;
  end process;
  
  -----------------------------------------------------------------------------
  -- Output logic (concurrent assignments)
  -- Matches Verilog: assign g[1] = (state == B);
  -----------------------------------------------------------------------------
  g(1) <= '1' when state = B else '0';
  g(2) <= '1' when state = C else '0';
  g(3) <= '1' when state = D else '0';

end architecture rtl;