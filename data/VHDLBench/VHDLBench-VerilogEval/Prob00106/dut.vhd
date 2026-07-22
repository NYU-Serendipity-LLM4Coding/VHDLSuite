-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: PS/2 scancode decoder for arrow keys

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    scancode : in  std_logic_vector(15 downto 0);
    left     : out std_logic;
    down     : out std_logic;
    right    : out std_logic;
    up       : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  process(scancode)
  begin
    -- Default: all outputs low
    up    <= '0';
    left  <= '0';
    down  <= '0';
    right <= '0';
    
    -- Decode scancodes
    case scancode is
      when x"e06b" =>
        left <= '1';
      when x"e072" =>
        down <= '1';
      when x"e074" =>
        right <= '1';
      when x"e075" =>
        up <= '1';
      when others =>
        null;
    end case;
  end process;

end architecture rtl;