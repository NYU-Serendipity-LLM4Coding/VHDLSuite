-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Serial Receiver FSM
-- State name change: 'DONE' -> 'ST_DONE' (to avoid conflict with port 'done')

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk       : in  std_logic;
    signal_in : in  std_logic;
    reset     : in  std_logic;
    out_byte  : out std_logic_vector(7 downto 0);
    done      : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  type state_t is (B0, B1, B2, B3, B4, B5, B6, B7, START, STOP, ST_DONE, ERR);
  signal state : state_t;
  signal next_state : state_t;
  signal byte_r : std_logic_vector(9 downto 0);
  
begin
  
  -- Next state logic
  process(state, signal_in)
  begin
    case state is
      when START =>
        if signal_in = '1' then
          next_state <= START;
        else
          next_state <= B0;
        end if;
      
      when B0 => next_state <= B1;
      when B1 => next_state <= B2;
      when B2 => next_state <= B3;
      when B3 => next_state <= B4;
      when B4 => next_state <= B5;
      when B5 => next_state <= B6;
      when B6 => next_state <= B7;
      when B7 => next_state <= STOP;
      
      when STOP =>
        if signal_in = '1' then
          next_state <= ST_DONE;
        else
          next_state <= ERR;
        end if;
      
      when ST_DONE =>
        if signal_in = '1' then
          next_state <= START;
        else
          next_state <= B0;
        end if;
      
      when ERR =>
        if signal_in = '1' then
          next_state <= START;
        else
          next_state <= ERR;
        end if;
      
      when others =>
        next_state <= START;
    end case;
  end process;
  
  -- State register
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= START;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  -- Data shift register
  process(clk)
  begin
    if rising_edge(clk) then
      byte_r <= signal_in & byte_r(9 downto 1);
    end if;
  end process;
  
  -- Output logic
  done <= '1' when (state = ST_DONE) else '0';
  out_byte <= byte_r(8 downto 1) when (state = ST_DONE) else (others => 'X');

end architecture rtl;