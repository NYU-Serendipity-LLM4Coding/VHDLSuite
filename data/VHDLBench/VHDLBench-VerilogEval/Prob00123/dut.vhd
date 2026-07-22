-- (4) DUT implementation (TopModule)
-- User's design under test (with bug fixed)
-- Bug in original Verilog: if (~out) checks bitwise NOT, not equality to zero
-- Bug also: missing else clause for result_is_zero
-- Fix: Use (out == 0) comparison and add else clause

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    do_sub         : in  std_logic;
    a              : in  std_logic_vector(7 downto 0);
    b              : in  std_logic_vector(7 downto 0);
    signal_out     : out std_logic_vector(7 downto 0);
    result_is_zero : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Matches corrected Verilog logic
  -- Critical: Calculate result_is_zero in same process as out assignment
  process(do_sub, a, b)
    variable temp_out : std_logic_vector(7 downto 0);
  begin
    -- Calculate output based on do_sub
    case do_sub is
      when '0' =>
        temp_out := std_logic_vector(unsigned(a) + unsigned(b));
      when '1' =>
        temp_out := std_logic_vector(unsigned(a) - unsigned(b));
      when others =>
        temp_out := (others => 'X');
    end case;
    
    -- Assign to output
    signal_out <= temp_out;
    
    -- Check if result is zero (FIXED: was ~out in buggy version)
    -- Must use temp_out (variable) not signal_out to get current value
    if unsigned(temp_out) = 0 then
      result_is_zero <= '1';
    else
      result_is_zero <= '0';
    end if;
  end process;

end architecture rtl;