-- (3) Reference implementation (RefModule)
-- Reference Module: PS/2 Scancode Decoder for Arrow Keys
-- Decodes 16-bit scancodes to detect arrow key presses
-- Scancode mapping:
--   16'he06b -> left arrow
--   16'he072 -> down arrow
--   16'he074 -> right arrow
--   16'he075 -> up arrow

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    scancode : in  std_logic_vector(15 downto 0);
    left     : out std_logic;
    down     : out std_logic;
    right    : out std_logic;
    up       : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: always @(*) begin
  --   {up, left, down, right} = 0;
  --   case (scancode) ...
  -- end
  process(scancode)
  begin
    -- Default: all outputs low
    up    <= '0';
    left  <= '0';
    down  <= '0';
    right <= '0';
    
    -- Case statement for scancode decoding
    case scancode is
      when x"e06b" =>  -- 16'he06b: left arrow
        left <= '1';
      when x"e072" =>  -- 16'he072: down arrow
        down <= '1';
      when x"e074" =>  -- 16'he074: right arrow
        right <= '1';
      when x"e075" =>  -- 16'he075: up arrow
        up <= '1';
      when others =>
        -- All remain 0 (already set)
        null;
    end case;
  end process;

end architecture rtl;