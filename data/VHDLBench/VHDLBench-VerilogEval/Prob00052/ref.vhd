-- (3) Reference implementation (RefModule)
-- Reference Module: 100-input Reduction Gates
-- Implements AND, OR, and XOR reduction operations
-- Variable name changes: 'in' -> 'signal_in' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    signal_in  : in  std_logic_vector(99 downto 0);
    out_and    : out std_logic;
    out_or     : out std_logic;
    out_xor    : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign out_and = &in;
  -- Reduction AND: all bits must be '1'
  out_and <= '1' when (signal_in = (signal_in'range => '1')) else '0';
  
  -- Matches Verilog: assign out_or = |in;
  -- Reduction OR: at least one bit must be '1'
  out_or <= '0' when (signal_in = (signal_in'range => '0')) else '1';
  
  -- Matches Verilog: assign out_xor = ^in;
  -- Reduction XOR: odd parity
  process(signal_in)
    variable temp : std_logic;
  begin
    temp := '0';
    for i in signal_in'range loop
      temp := temp xor signal_in(i);
    end loop;
    out_xor <= temp;
  end process;

end architecture rtl;