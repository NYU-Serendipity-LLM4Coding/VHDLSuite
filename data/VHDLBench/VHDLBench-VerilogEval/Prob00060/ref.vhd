-- (3) Reference implementation (RefModule)
-- Reference Module: 4-bit Shift Register
-- Synchronous active-low reset
-- Shifts in from LSB, outputs MSB
-- Matches Verilog: sr <= {sr[2:0], in}
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out'

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk        : in  std_logic;
    resetn     : in  std_logic;
    signal_in  : in  std_logic;
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  -- 4-bit shift register
  signal sr : std_logic_vector(3 downto 0) := "0000";
begin
  
  -- Output is MSB of shift register
  -- Matches Verilog: assign out = sr[3];
  signal_out <= sr(3);
  
  -- Shift register process
  -- Matches Verilog: always @(posedge clk)
  process(clk)
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        -- Matches Verilog: if (~resetn) sr <= '0;
        sr <= (others => '0');
      else
        -- Matches Verilog: sr <= {sr[2:0], in};
        -- Shift left, insert new bit at LSB
        sr <= sr(2 downto 0) & signal_in;
      end if;
    end if;
  end process;

end architecture rtl;