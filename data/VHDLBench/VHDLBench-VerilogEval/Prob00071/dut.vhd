-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Priority encoder for 8-bit input

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    signal_in : in  std_logic_vector(7 downto 0);
    pos       : out std_logic_vector(2 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  process(signal_in)
  begin
    -- Default: no bits set
    pos <= "000";
    
    -- Priority encoder: find least significant '1'
    if signal_in(0) = '1' then
      pos <= "000";
    elsif signal_in(1) = '1' then
      pos <= "001";
    elsif signal_in(2) = '1' then
      pos <= "010";
    elsif signal_in(3) = '1' then
      pos <= "011";
    elsif signal_in(4) = '1' then
      pos <= "100";
    elsif signal_in(5) = '1' then
      pos <= "101";
    elsif signal_in(6) = '1' then
      pos <= "110";
    elsif signal_in(7) = '1' then
      pos <= "111";
    end if;
  end process;

end architecture rtl;