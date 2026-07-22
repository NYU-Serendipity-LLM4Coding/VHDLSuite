-- (2) DUT implementation (pulse_detect)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pulse_detect is
  port (
    clk      : in  std_logic;
    rst_n    : in  std_logic;
    data_in  : in  std_logic;
    data_out : out std_logic
  );
end entity pulse_detect;

architecture rtl of pulse_detect is
  -- State encoding
  type state_t is (s0, s1, s2, s3);
  signal pulse_level1 : state_t;
  signal pulse_level2 : state_t;
  
begin

  -- State register
  state_reg_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      pulse_level1 <= s0;
    elsif rising_edge(clk) then
      pulse_level1 <= pulse_level2;
    end if;
  end process;
  
  -- Next state logic
  next_state_proc : process(pulse_level1, data_in)
  begin
    case pulse_level1 is
      when s0 =>
        if data_in = '0' then
          pulse_level2 <= s1;
        else
          pulse_level2 <= s0;
        end if;
        
      when s1 =>
        if data_in = '1' then
          pulse_level2 <= s2;
        else
          pulse_level2 <= s1;
        end if;
        
      when s2 =>
        if data_in = '0' then
          pulse_level2 <= s3;
        else
          pulse_level2 <= s0;
        end if;
        
      when s3 =>
        if data_in = '1' then
          pulse_level2 <= s2;
        else
          pulse_level2 <= s1;
        end if;
        
      when others =>
        pulse_level2 <= s0;
    end case;
  end process;
  
  -- Output logic (combinational)
  output_proc : process(rst_n, pulse_level1, data_in)
  begin
    if rst_n = '0' then
      data_out <= '0';
    elsif pulse_level1 = s2 and data_in = '0' then
      data_out <= '1';
    else
      data_out <= '0';
    end if;
  end process;
  
end architecture rtl;