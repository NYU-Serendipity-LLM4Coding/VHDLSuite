-- (3) Reference implementation (RefModule)
-- Reference Module: 2-to-1 Multiplexer
-- Two implementations: concurrent assignment and process
-- Select b when (sel_b1 AND sel_b2), otherwise select a

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    a          : in  std_logic;
    b          : in  std_logic;
    sel_b1     : in  std_logic;
    sel_b2     : in  std_logic;
    out_assign : out std_logic;
    out_always : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign out_assign = (sel_b1 & sel_b2) ? b : a;
  out_assign <= b when (sel_b1 = '1' and sel_b2 = '1') else a;
  
  -- Matches Verilog: always @(*) out_always = (sel_b1 & sel_b2) ? b : a;
  process(a, b, sel_b1, sel_b2)
  begin
    if (sel_b1 = '1' and sel_b2 = '1') then
      out_always <= b;
    else
      out_always <= a;
    end if;
  end process;

end architecture rtl;