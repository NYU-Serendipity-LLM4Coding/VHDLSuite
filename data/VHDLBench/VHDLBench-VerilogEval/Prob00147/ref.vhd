-- (3) Reference implementation (RefModule)
-- Reference Module: Sequential Full Adder Carry Chain
-- This implements a 1-bit full adder with registered carry
-- state (c) = majority function of (a, b, c_prev) = carry output
-- q = a XOR b XOR c (sum output)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk   : in  std_logic;
    a     : in  std_logic;
    b     : in  std_logic;
    q     : out std_logic;
    state : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  -- Internal register for carry (matches Verilog: reg c;)
  signal c : std_logic := '0';
begin
  
  -- Matches Verilog: always @(posedge clk) c <= a&b | a&c | b&c;
  -- This is the majority function (carry out of full adder)
  process(clk)
  begin
    if rising_edge(clk) then
      c <= (a and b) or (a and c) or (b and c);
    end if;
  end process;
  
  -- Matches Verilog: assign q = a^b^c;
  -- This is the sum output of full adder
  q <= a xor b xor c;
  
  -- Matches Verilog: assign state = c;
  -- Make internal carry visible
  state <= c;

end architecture rtl;