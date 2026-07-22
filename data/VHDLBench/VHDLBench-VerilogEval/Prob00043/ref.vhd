-- (3) Reference implementation (RefModule)
-- Reference Module: Pairwise Comparison
-- Computes 25 pairwise one-bit comparisons
-- out[24:0] compares each bit with every bit (including itself)
-- Variable name changes: 'out' -> 'signal_out' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    a          : in  std_logic;
    b          : in  std_logic;
    c          : in  std_logic;
    d          : in  std_logic;
    e          : in  std_logic;
    signal_out : out std_logic_vector(24 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  signal inverted_replicated : std_logic_vector(24 downto 0);
  signal normal_replicated   : std_logic_vector(24 downto 0);
begin
  
  -- Matches Verilog: ~{ {5{a}}, {5{b}}, {5{c}}, {5{d}}, {5{e}} }
  -- This creates: ~{aaaaa, bbbbb, ccccc, ddddd, eeeee}
  inverted_replicated <= not (
    (4 downto 0 => a) &   -- {5{a}}
    (4 downto 0 => b) &   -- {5{b}}
    (4 downto 0 => c) &   -- {5{c}}
    (4 downto 0 => d) &   -- {5{d}}
    (4 downto 0 => e)     -- {5{e}}
  );
  
  -- Matches Verilog: {5{a,b,c,d,e}}
  -- This creates: {abcde, abcde, abcde, abcde, abcde}
  normal_replicated <= 
    (a & b & c & d & e) &
    (a & b & c & d & e) &
    (a & b & c & d & e) &
    (a & b & c & d & e) &
    (a & b & c & d & e);
  
  -- Matches Verilog: assign out = ~{...} ^ {...};
  signal_out <= inverted_replicated xor normal_replicated;

end architecture rtl;