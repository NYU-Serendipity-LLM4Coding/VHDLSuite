-- (3) Reference implementation (RefModule)
-- Reference Module: Logic Gates Collection
-- Implements 7 basic logic operations on inputs a and b
-- Note: Verilog uses ~^ for XNOR; this is equivalent to a xnor b

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    a         : in  std_logic;
    b         : in  std_logic;
    out_and   : out std_logic;
    out_or    : out std_logic;
    out_xor   : out std_logic;
    out_nand  : out std_logic;
    out_nor   : out std_logic;
    out_xnor  : out std_logic;
    out_anotb : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign out_and = a&b;
  out_and <= a and b;
  
  -- Matches Verilog: assign out_or = a|b;
  out_or <= a or b;
  
  -- Matches Verilog: assign out_xor = a^b;
  out_xor <= a xor b;
  
  -- Matches Verilog: assign out_nand = ~(a&b);
  out_nand <= a nand b;
  
  -- Matches Verilog: assign out_nor = ~(a|b);
  out_nor <= a nor b;
  
  -- Matches Verilog: assign out_xnor = a^~b;
  -- Note: a^~b is XNOR in Verilog (equivalent to ~(a^b))
  out_xnor <= a xnor b;
  
  -- Matches Verilog: assign out_anotb = a & ~b;
  out_anotb <= a and (not b);

end architecture rtl;