-- (3) Reference implementation (RefModule)
-- Reference Module: FSM Circuit with 3-bit state register
-- State update: s <= { s[2] ^ x, ~s[1] & x, ~s[0] | x }
-- Output: z = ~|s (NOR of all state bits)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk : in  std_logic;
    x   : in  std_logic;
    z   : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  -- Matches Verilog: reg [2:0] s = 0;
  signal s : std_logic_vector(2 downto 0) := "000";
begin
  
  -- Matches Verilog: assign z = ~|s;
  -- NOR reduction: z = NOT (s(2) OR s(1) OR s(0))
  z <= not (s(2) or s(1) or s(0));
  
  -- Matches Verilog: always @(posedge clk) begin
  --   s <= { s[2] ^ x, ~s[1] & x, ~s[0] | x };
  -- end
  process(clk)
  begin
    if rising_edge(clk) then
      -- s[2] <= s[2] ^ x       (XOR gate)
      -- s[1] <= ~s[1] & x      (AND gate with inverted s[1])
      -- s[0] <= ~s[0] | x      (OR gate with inverted s[0])
      s(2) <= s(2) xor x;
      s(1) <= (not s(1)) and x;
      s(0) <= (not s(0)) or x;
    end if;
  end process;

end architecture rtl;