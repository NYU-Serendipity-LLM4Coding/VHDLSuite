-- (3) Reference implementation (RefModule)
-- Reference Module: 4-bit Shift/Counter Register
-- Shifts MSB-first when shift_ena=1, counts down when count_ena=1
-- Corresponds to Verilog RefModule

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk       : in  std_logic;
    shift_ena : in  std_logic;
    count_ena : in  std_logic;
    data      : in  std_logic;
    q         : out std_logic_vector(3 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  signal q_reg : std_logic_vector(3 downto 0) := "0000";
begin
  
  q <= q_reg;
  
  -- Matches Verilog: always @(posedge clk)
  process(clk)
  begin
    if rising_edge(clk) then
      if shift_ena = '1' then
        -- Matches Verilog: q <= { q[2:0], data };
        -- Shift left, insert data at LSB
        q_reg <= q_reg(2 downto 0) & data;
      elsif count_ena = '1' then
        -- Matches Verilog: q <= q - 1'b1;
        q_reg <= std_logic_vector(unsigned(q_reg) - 1);
      end if;
    end if;
  end process;

end architecture rtl;