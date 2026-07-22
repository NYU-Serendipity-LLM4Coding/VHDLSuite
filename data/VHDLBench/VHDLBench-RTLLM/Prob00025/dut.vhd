-- (2) DUT implementation (sequence_detector)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sequence_detector is
  port (
    clk                : in  std_logic;
    rst_n              : in  std_logic;
    data_in            : in  std_logic;
    sequence_detected  : out std_logic
  );
end entity sequence_detector;

architecture rtl of sequence_detector is
  
  -- State encoding (one-hot)
  type state_t is (IDLE, S1, S2, S3, S4);
  signal curr_state : state_t;
  signal next_state : state_t;
  
begin

  -- State register
  state_reg_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      curr_state <= IDLE;
    elsif rising_edge(clk) then
      curr_state <= next_state;
    end if;
  end process;
  
  -- Next state logic
  next_state_proc : process(curr_state, data_in, rst_n)
  begin
    if rst_n = '0' then
      next_state <= IDLE;
    else
      case curr_state is
        when IDLE =>
          if data_in = '1' then
            next_state <= S1;
          else
            next_state <= IDLE;
          end if;
          
        when S1 =>
          if data_in = '1' then
            next_state <= S1;
          else
            next_state <= S2;
          end if;
          
        when S2 =>
          if data_in = '1' then
            next_state <= S1;
          else
            next_state <= S3;
          end if;
          
        when S3 =>
          if data_in = '1' then
            next_state <= S4;
          else
            next_state <= IDLE;
          end if;
          
        when S4 =>
          if data_in = '1' then
            next_state <= S1;
          else
            next_state <= S2;
          end if;
          
        when others =>
          next_state <= IDLE;
      end case;
    end if;
  end process;
  
  -- Output logic
  sequence_detected <= '1' when curr_state = S4 else '0';
  
end architecture rtl;