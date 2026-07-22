-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement 7 logic gate outputs

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
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
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- (1) out_and: a and b
  out_and <= a and b;
  
  -- (2) out_or: a or b
  out_or <= a or b;
  
  -- (3) out_xor: a xor b
  out_xor <= a xor b;
  
  -- (4) out_nand: a nand b
  out_nand <= a nand b;
  
  -- (5) out_nor: a nor b
  out_nor <= a nor b;
  
  -- (6) out_xnor: a xnor b
  out_xnor <= a xnor b;
  
  -- (7) out_anotb: a and-not b
  out_anotb <= a and (not b);

end architecture rtl;