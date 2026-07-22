-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: FSM Arbiter with priority r(1) > r(2) > r(3)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk    : in  std_logic;
    resetn : in  std_logic;
    r      : in  std_logic_vector(3 downto 1);
    g      : out std_logic_vector(3 downto 1)
  );
end entity TopModule;

architecture rtl of TopModule is
  
  -- State encoding
  type state_type is (A, B, C, D);
  signal state, next_state : state_type;
  
begin

  -- State register with synchronous reset
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
  
  -- Next state logic
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
        next_state <= A;
    end case;
  end process;
  
  -- Output logic
  g(1) <= '1' when state = B else '0';
  g(2) <= '1' when state = C else '0';
  g(3) <= '1' when state = D else '0';

end architecture rtl;