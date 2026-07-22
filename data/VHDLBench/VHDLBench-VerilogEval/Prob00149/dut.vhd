-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement water level control FSM

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    s     : in  std_logic_vector(3 downto 1);
    fr3   : out std_logic;
    fr2   : out std_logic;
    fr1   : out std_logic;
    dfr   : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  type state_t is (A2, B1, B2, C1, C2, D1);
  signal state, next_state : state_t;
  signal fr : std_logic_vector(3 downto 0);
  
begin
  
  fr3 <= fr(3);
  fr2 <= fr(2);
  fr1 <= fr(1);
  dfr <= fr(0);
  
  state_reg : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= A2;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  next_state_logic : process(state, s)
  begin
    case state is
      when A2 =>
        if s(1) = '1' then
          next_state <= B1;
        else
          next_state <= A2;
        end if;
        
      when B1 =>
        if s(2) = '1' then
          next_state <= C1;
        elsif s(1) = '1' then
          next_state <= B1;
        else
          next_state <= A2;
        end if;
        
      when B2 =>
        if s(2) = '1' then
          next_state <= C1;
        elsif s(1) = '1' then
          next_state <= B2;
        else
          next_state <= A2;
        end if;
        
      when C1 =>
        if s(3) = '1' then
          next_state <= D1;
        elsif s(2) = '1' then
          next_state <= C1;
        else
          next_state <= B2;
        end if;
        
      when C2 =>
        if s(3) = '1' then
          next_state <= D1;
        elsif s(2) = '1' then
          next_state <= C2;
        else
          next_state <= B2;
        end if;
        
      when D1 =>
        if s(3) = '1' then
          next_state <= D1;
        else
          next_state <= C2;
        end if;
        
      when others =>
        next_state <= A2;
    end case;
  end process;
  
  output_logic : process(state)
  begin
    case state is
      when A2 =>
        fr <= "1111";
      when B1 =>
        fr <= "0110";
      when B2 =>
        fr <= "0111";
      when C1 =>
        fr <= "0010";
      when C2 =>
        fr <= "0011";
      when D1 =>
        fr <= "0000";
      when others =>
        fr <= "XXXX";
    end case;
  end process;

end architecture rtl;