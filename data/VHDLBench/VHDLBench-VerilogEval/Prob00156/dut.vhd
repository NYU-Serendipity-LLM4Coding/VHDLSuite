-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement Timer FSM with pattern detection

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk      : in  std_logic;
    reset    : in  std_logic;
    data     : in  std_logic;
    count    : out std_logic_vector(3 downto 0);
    counting : out std_logic;
    done     : out std_logic;
    ack      : in  std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  type state_t is (S, S1, S11, S110, B0, B1, B2, B3, CountState, WaitState);
  
  signal state, next_state : state_t := S;
  
  signal shift_ena      : std_logic := '0';
  signal fcount         : unsigned(9 downto 0) := (others => '0');
  signal scount         : std_logic_vector(3 downto 0) := (others => '0');
  signal done_counting  : std_logic;
  signal counting_reg   : std_logic := '0';
  signal done_reg       : std_logic := '0';
  
begin

  counting <= counting_reg;
  done <= done_reg;
  count <= scount when counting_reg = '1' else (others => 'X');
  
  done_counting <= '1' when (unsigned(scount) = 0) and (fcount = 999) else '0';
  
  process(state, data, done_counting, ack)
  begin
    case state is
      when S =>
        if data = '1' then
          next_state <= S1;
        else
          next_state <= S;
        end if;
        
      when S1 =>
        if data = '1' then
          next_state <= S11;
        else
          next_state <= S;
        end if;
        
      when S11 =>
        if data = '1' then
          next_state <= S11;
        else
          next_state <= S110;
        end if;
        
      when S110 =>
        if data = '1' then
          next_state <= B0;
        else
          next_state <= S;
        end if;
        
      when B0 =>
        next_state <= B1;
        
      when B1 =>
        next_state <= B2;
        
      when B2 =>
        next_state <= B3;
        
      when B3 =>
        next_state <= CountState;
        
      when CountState =>
        if done_counting = '1' then
          next_state <= WaitState;
        else
          next_state <= CountState;
        end if;
        
      when WaitState =>
        if ack = '1' then
          next_state <= S;
        else
          next_state <= WaitState;
        end if;
        
      when others =>
        next_state <= S;
    end case;
  end process;
  
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= S;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  process(state)
  begin
    shift_ena <= '0';
    counting_reg <= '0';
    done_reg <= '0';
    
    case state is
      when B0 | B1 | B2 | B3 =>
        shift_ena <= '1';
        
      when CountState =>
        counting_reg <= '1';
        
      when WaitState =>
        done_reg <= '1';
        
      when others =>
        null;
    end case;
  end process;
  
  process(clk)
  begin
    if rising_edge(clk) then
      if shift_ena = '1' then
        scount <= scount(2 downto 0) & data;
      elsif counting_reg = '1' and fcount = 999 then
        scount <= std_logic_vector(unsigned(scount) - 1);
      end if;
    end if;
  end process;
  
  process(clk)
  begin
    if rising_edge(clk) then
      if counting_reg = '0' then
        fcount <= (others => '0');
      elsif fcount = 999 then
        fcount <= (others => '0');
      else
        fcount <= fcount + 1;
      end if;
    end if;
  end process;

end architecture rtl;