-- (3) Reference implementation (RefModule)
-- Reference Module: Down-Counter Timer
-- Counts down from loaded value, asserts tc when count reaches 0
-- Load has priority over count-down
-- Counter stops at 0 until reloaded

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk  : in  std_logic;
    load : in  std_logic;
    data : in  std_logic_vector(9 downto 0);
    tc   : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  -- Matches Verilog: logic [9:0] count_value;
  signal count_value : unsigned(9 downto 0) := (others => '0');
begin
  
  -- Matches Verilog: assign tc = count_value == 0;
  tc <= '1' when count_value = 0 else '0';
  
  -- Matches Verilog: always @(posedge clk)
  process(clk)
  begin
    if rising_edge(clk) then
      if load = '1' then
        -- Matches Verilog: if(load) count_value <= data;
        count_value <= unsigned(data);
      elsif count_value /= 0 then
        -- Matches Verilog: else if(count_value != 0) count_value <= count_value - 1;
        count_value <= count_value - 1;
      end if;
    end if;
  end process;

end architecture rtl;