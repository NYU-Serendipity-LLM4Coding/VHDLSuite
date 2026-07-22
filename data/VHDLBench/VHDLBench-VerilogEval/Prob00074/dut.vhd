-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: FSM with 3 flip-flops and combinational logic
-- Circuit description:
--   - Flip-flop 0: D = NOT(s[0]) OR x
--   - Flip-flop 1: D = NOT(s[1]) AND x
--   - Flip-flop 2: D = s[2] XOR x
--   - Output z: NOR of all three flip-flop outputs

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk : in  std_logic;
    x   : in  std_logic;
    z   : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal s : std_logic_vector(2 downto 0) := "000";
begin
  
  -- Three-input NOR gate for output
  z <= not (s(2) or s(1) or s(0));
  
  -- Three D flip-flops with different combinational logic
  process(clk)
  begin
    if rising_edge(clk) then
      -- Flip-flop 2: XOR gate (x XOR s[2])
      s(2) <= s(2) xor x;
      
      -- Flip-flop 1: AND gate (x AND NOT(s[1]))
      s(1) <= (not s(1)) and x;
      
      -- Flip-flop 0: OR gate (x OR NOT(s[0]))
      s(0) <= (not s(0)) or x;
    end if;
  end process;

end architecture rtl;