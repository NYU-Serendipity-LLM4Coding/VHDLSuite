-- (3) Reference implementation (RefModule)
-- Reference Module: Adder-Subtractor with Zero Flag
-- When do_sub=0: out = a + b
-- When do_sub=1: out = a - b
-- result_is_zero = (out == 0)
-- Variable name changes: 'out' -> 'signal_out' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    do_sub         : in  std_logic;
    a              : in  std_logic_vector(7 downto 0);
    b              : in  std_logic_vector(7 downto 0);
    signal_out     : out std_logic_vector(7 downto 0);
    result_is_zero : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  signal out_internal : std_logic_vector(7 downto 0);
begin
  
  -- Matches Verilog: always @(*) begin case (do_sub) ... endcase
  process(do_sub, a, b)
  begin
    case do_sub is
      when '0' =>
        out_internal <= std_logic_vector(unsigned(a) + unsigned(b));
      when '1' =>
        out_internal <= std_logic_vector(unsigned(a) - unsigned(b));
      when others =>
        out_internal <= (others => 'X');
    end case;
  end process;
  
  signal_out <= out_internal;
  
  -- Matches Verilog: result_is_zero = (out == 0);
  result_is_zero <= '1' when (unsigned(out_internal) = 0) else '0';

end architecture rtl;