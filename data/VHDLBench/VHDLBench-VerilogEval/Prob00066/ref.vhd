-- (3) Reference implementation (RefModule)
-- Reference Module: Edge Detector with Capture
-- Detects 1-to-0 transitions on each bit and holds until reset
-- Matches Verilog: out <= out | (~in & d_last)
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out'

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk        : in  std_logic;
    reset      : in  std_logic;
    signal_in  : in  std_logic_vector(31 downto 0);
    signal_out : out std_logic_vector(31 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  signal d_last  : std_logic_vector(31 downto 0) := (others => '0');
  signal out_reg : std_logic_vector(31 downto 0) := (others => '0');
begin
  
  signal_out <= out_reg;
  
  -- Matches Verilog: always @(posedge clk) begin
  --   d_last <= in;
  --   if (reset) out <= '0;
  --   else out <= out | (~in & d_last);
  -- end
  process(clk)
  begin
    if rising_edge(clk) then
      d_last <= signal_in;
      
      if reset = '1' then
        out_reg <= (others => '0');
      else
        -- Detect 1-to-0 transition: (~in & d_last)
        -- Accumulate: out | (transition)
        out_reg <= out_reg or ((not signal_in) and d_last);
      end if;
    end if;
  end process;

end architecture rtl;