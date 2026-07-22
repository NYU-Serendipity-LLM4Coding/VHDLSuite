-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement 100-input AND, OR, and XOR reduction gates

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    signal_in  : in  std_logic_vector(99 downto 0);
    out_and    : out std_logic;
    out_or     : out std_logic;
    out_xor    : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Reduction AND
  out_and <= '1' when (signal_in = (signal_in'range => '1')) else '0';
  
  -- Reduction OR
  out_or <= '0' when (signal_in = (signal_in'range => '0')) else '1';
  
  -- Reduction XOR
  process(signal_in)
    variable temp : std_logic;
  begin
    temp := '0';
    for i in signal_in'range loop
      temp := temp xor signal_in(i);
    end loop;
    out_xor <= temp;
  end process;

end architecture rtl;