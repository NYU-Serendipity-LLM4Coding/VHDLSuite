-- (3) Reference implementation (RefModule)
-- Reference Module: Vector Concatenation and Split
-- Concatenates six 5-bit inputs and appends "11", then splits into four 8-bit outputs
-- {w,x,y,z} = {a,b,c,d,e,f,2'b11}
-- Total: 30 bits input + 2 bits constant = 32 bits output

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    a : in  std_logic_vector(4 downto 0);
    b : in  std_logic_vector(4 downto 0);
    c : in  std_logic_vector(4 downto 0);
    d : in  std_logic_vector(4 downto 0);
    e : in  std_logic_vector(4 downto 0);
    f : in  std_logic_vector(4 downto 0);
    w : out std_logic_vector(7 downto 0);
    x : out std_logic_vector(7 downto 0);
    y : out std_logic_vector(7 downto 0);
    z : out std_logic_vector(7 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  -- Intermediate 32-bit concatenation signal
  signal concat : std_logic_vector(31 downto 0);
begin
  
  -- Matches Verilog: assign {w,x,y,z} = {a,b,c,d,e,f,2'b11};
  -- Concatenate: a[4:0] & b[4:0] & c[4:0] & d[4:0] & e[4:0] & f[4:0] & "11"
  concat <= a & b & c & d & e & f & "11";
  
  -- Split into outputs
  -- w gets bits [31:24], x gets [23:16], y gets [15:8], z gets [7:0]
  w <= concat(31 downto 24);
  x <= concat(23 downto 16);
  y <= concat(15 downto 8);
  z <= concat(7 downto 0);

end architecture rtl;