-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Message boundary FSM with datapath

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk       : in  std_logic;
    signal_in : in  std_logic_vector(7 downto 0);
    reset     : in  std_logic;
    out_bytes : out std_logic_vector(23 downto 0);
    done      : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  type state_type is (BYTE1, BYTE2, BYTE3, DONE_STATE);
  signal state : state_type;
  signal next_state : state_type;
  
  signal out_bytes_r : std_logic_vector(23 downto 0);
  signal in3 : std_logic;
  
begin

  in3 <= signal_in(3);
  
  -- Next state logic
  process(state, in3)
  begin
    case state is
      when BYTE1 =>
        if in3 = '1' then
          next_state <= BYTE2;
        else
          next_state <= BYTE1;
        end if;
        
      when BYTE2 =>
        next_state <= BYTE3;
        
      when BYTE3 =>
        next_state <= DONE_STATE;
        
      when DONE_STATE =>
        if in3 = '1' then
          next_state <= BYTE2;
        else
          next_state <= BYTE1;
        end if;
        
    end case;
  end process;
  
  -- State register
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= BYTE1;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  -- Done output
  done <= '1' when (state = DONE_STATE) else '0';
  
  -- Datapath
  process(clk)
  begin
    if rising_edge(clk) then
      out_bytes_r <= out_bytes_r(15 downto 0) & signal_in;
    end if;
  end process;
  
  -- Output
  out_bytes <= out_bytes_r when (state = DONE_STATE) else (others => '-');

end architecture rtl;