-- (4) DUT implementation (TopModule)
-- Hierarchical design with modules A and B
-- Module A: z = (x^y) & x
-- Module B: z = ~(x^y) = XNOR (from waveform analysis)
-- Architecture: (A1|B1) XOR (A2&B2)

-- Module A Entity
library ieee;
use ieee.std_logic_1164.all;

entity ModuleA is
  port (
    x : in  std_logic;
    y : in  std_logic;
    z : out std_logic
  );
end entity ModuleA;

architecture rtl of ModuleA is
begin
  -- z = (x^y) & x
  z <= (x xor y) and x;
end architecture rtl;

-- Module B Entity
library ieee;
use ieee.std_logic_1164.all;

entity ModuleB is
  port (
    x : in  std_logic;
    y : in  std_logic;
    z : out std_logic
  );
end entity ModuleB;

architecture rtl of ModuleB is
begin
  -- From waveform: x=0,y=0->1; x=1,y=0->0; x=0,y=1->0; x=1,y=1->1
  -- This is XNOR: z = ~(x^y)
  z <= not (x xor y);
end architecture rtl;

-- Top Module Entity
library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    x : in  std_logic;
    y : in  std_logic;
    z : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal a1_out : std_logic;
  signal b1_out : std_logic;
  signal a2_out : std_logic;
  signal b2_out : std_logic;
  signal or_out : std_logic;
  signal and_out : std_logic;
begin

  -- First pair: A1 and B1
  inst_a1 : entity work.ModuleA
    port map (
      x => x,
      y => y,
      z => a1_out
    );
  
  inst_b1 : entity work.ModuleB
    port map (
      x => x,
      y => y,
      z => b1_out
    );
  
  -- Second pair: A2 and B2
  inst_a2 : entity work.ModuleA
    port map (
      x => x,
      y => y,
      z => a2_out
    );
  
  inst_b2 : entity work.ModuleB
    port map (
      x => x,
      y => y,
      z => b2_out
    );
  
  -- OR gate for first pair
  or_out <= a1_out or b1_out;
  
  -- AND gate for second pair
  and_out <= a2_out and b2_out;
  
  -- XOR gate for final output
  z <= or_out xor and_out;

end architecture rtl;