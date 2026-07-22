-- (3) Reference implementation (RefModule)
-- Reference Module: Population Count (255-bit)
-- Counts number of '1' bits in 255-bit input vector
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out'

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    signal_in  : in  std_logic_vector(254 downto 0);
    signal_out : out std_logic_vector(7 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: always_comb begin ... end
  process(signal_in)
    variable count : integer range 0 to 255;
  begin
    count := 0;
    
    -- Matches Verilog: for (int i=0; i<255; i++) out = out + in[i];
    for i in 0 to 254 loop
      if signal_in(i) = '1' then
        count := count + 1;
      end if;
    end loop;
    
    signal_out <= std_logic_vector(to_unsigned(count, 8));
  end process;

end architecture rtl;