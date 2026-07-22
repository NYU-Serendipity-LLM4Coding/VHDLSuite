-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: 255-bit population count

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    signal_in  : in  std_logic_vector(254 downto 0);
    signal_out : out std_logic_vector(7 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  process(signal_in)
    variable count : integer range 0 to 255;
  begin
    count := 0;
    
    for i in 0 to 254 loop
      if signal_in(i) = '1' then
        count := count + 1;
      end if;
    end loop;
    
    signal_out <= std_logic_vector(to_unsigned(count, 8));
  end process;

end architecture rtl;