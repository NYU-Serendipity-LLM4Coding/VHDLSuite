-- (3) Reference implementation (RefModule)
-- Reference Module: XOR Gate Three Ways
-- Implements XOR using:
--   1. Concurrent assignment (out_assign)
--   2. Combinational process (out_always_comb)
--   3. Clocked process (out_always_ff) - introduces 1 clock delay

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk             : in  std_logic;
    a               : in  std_logic;
    b               : in  std_logic;
    out_assign      : out std_logic;
    out_always_comb : out std_logic;
    out_always_ff   : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Method 1: Concurrent assignment
  -- Matches Verilog: assign out_assign = a ^ b;
  out_assign <= a xor b;
  
  -- Method 2: Combinational process
  -- Matches Verilog: always @(*) out_always_comb = a ^ b;
  process(a, b)
  begin
    out_always_comb <= a xor b;
  end process;
  
  -- Method 3: Clocked process (introduces flip-flop)
  -- Matches Verilog: always @(posedge clk) out_always_ff <= a ^ b;
  process(clk)
  begin
    if rising_edge(clk) then
      out_always_ff <= a xor b;
    end if;
  end process;

end architecture rtl;