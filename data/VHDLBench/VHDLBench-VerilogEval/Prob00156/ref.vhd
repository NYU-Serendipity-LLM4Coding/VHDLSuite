-- (3) Reference implementation (RefModule)
-- Reference Module: Timer FSM with Pattern Detection
-- Detects pattern 1101, shifts in 4-bit delay, counts (delay+1)*1000 cycles

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk      : in  std_logic;
    reset    : in  std_logic;
    data     : in  std_logic;
    count    : out std_logic_vector(3 downto 0);
    counting : out std_logic;
    done     : out std_logic;
    ack      : in  std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State type matching Verilog enum
  type state_t is (S, S1, S11, S110, B0, B1, B2, B3, CountState, WaitState);
  
  signal state, next_state : state_t := S;
  
  signal shift_ena      : std_logic := '0';
  signal fcount         : unsigned(9 downto 0) := (others => '0');
  signal scount         : std_logic_vector(3 downto 0) := (others => '0');
  signal done_counting  : std_logic;
  signal counting_reg   : std_logic := '0';
  signal done_reg       : std_logic := '0';
  
begin

  -- Output assignments
  counting <= counting_reg;
  done <= done_reg;
  
  -- count output is X when not counting (matches Verilog: assign count = counting ? scount : 'x;)
  count <= scount when counting_reg = '1' else (others => 'X');
  
  -- Done counting when scount = 0 and fcount = 999
  done_counting <= '1' when (unsigned(scount) = 0) and (fcount = 999) else '0';
  
  -- Next state logic (combinational)
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
  
  -- State register
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
  
  -- Output decode logic (combinational)
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
  
  -- Shift register (scount)
  process(clk)
  begin
    if rising_edge(clk) then
      if shift_ena = '1' then
        -- Matches Verilog: scount <= {scount[2:0], data};
        scount <= scount(2 downto 0) & data;
      elsif counting_reg = '1' and fcount = 999 then
        -- Matches Verilog: scount <= scount - 1'b1;
        scount <= std_logic_vector(unsigned(scount) - 1);
      end if;
    end if;
  end process;
  
  -- Fast counter (fcount)
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