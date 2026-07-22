-- (3) Reference implementation (RefModule)
-- Reference Module: Priority Encoder
-- Finds the position of the least significant '1' bit in an 8-bit input
-- Returns 0 if no bits are high
-- Variable name changes: 'in' -> 'signal_in' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    signal_in : in  std_logic_vector(7 downto 0);
    pos       : out std_logic_vector(2 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: always @(*) begin casez (in) ... endcase end
  process(signal_in)
  begin
    -- Default case (no bits set)
    pos <= "000";
    
    -- Check from LSB to MSB (priority to lower bits)
    -- Matches Verilog casez logic with don't-care matching
    if signal_in(0) = '1' then
      pos <= "000";  -- bit 0 is set
    elsif signal_in(1) = '1' then
      pos <= "001";  -- bit 1 is set
    elsif signal_in(2) = '1' then
      pos <= "010";  -- bit 2 is set
    elsif signal_in(3) = '1' then
      pos <= "011";  -- bit 3 is set
    elsif signal_in(4) = '1' then
      pos <= "100";  -- bit 4 is set
    elsif signal_in(5) = '1' then
      pos <= "101";  -- bit 5 is set
    elsif signal_in(6) = '1' then
      pos <= "110";  -- bit 6 is set
    elsif signal_in(7) = '1' then
      pos <= "111";  -- bit 7 is set
    end if;
  end process;

end architecture rtl;