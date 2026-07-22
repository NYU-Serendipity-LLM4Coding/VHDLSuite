-- (3) Reference implementation (RefModule)
-- Reference Module: K-map MUX Input Generator
-- Generates mux_in[3:0] based on inputs c and d
-- mux_in[0] = c OR d
-- mux_in[1] = 0
-- mux_in[2] = NOT d
-- mux_in[3] = c AND d

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    c      : in  std_logic;
    d      : in  std_logic;
    mux_in : out std_logic_vector(3 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign mux_in[0] = c | d;
  mux_in(0) <= c or d;
  
  -- Matches Verilog: assign mux_in[1] = 0;
  mux_in(1) <= '0';
  
  -- Matches Verilog: assign mux_in[2] = ~d;
  mux_in(2) <= not d;
  
  -- Matches Verilog: assign mux_in[3] = c&d;
  mux_in(3) <= c and d;

end architecture rtl;