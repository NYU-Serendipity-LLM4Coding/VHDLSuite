-- (3) Reference implementation (RefModule)
-- Reference Module: 100-bit Left/Right Rotator
-- Synchronous load and rotation control
-- ena = 2'b01: rotate right, ena = 2'b10: rotate left

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk  : in  std_logic;
    load : in  std_logic;
    ena  : in  std_logic_vector(1 downto 0);
    data : in  std_logic_vector(99 downto 0);
    q    : out std_logic_vector(99 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  signal q_reg : std_logic_vector(99 downto 0) := (others => '0');
begin
  
  q <= q_reg;
  
  -- Matches Verilog: always @(posedge clk)
  process(clk)
  begin
    if rising_edge(clk) then
      if load = '1' then
        -- Matches Verilog: if (load) q <= data;
        q_reg <= data;
      elsif ena = "01" then
        -- Matches Verilog: else if (ena == 2'h1) q <= {q[0], q[99:1]};
        -- Rotate right: bit 0 goes to bit 99, bits 99:1 shift to 98:0
        q_reg <= q_reg(0) & q_reg(99 downto 1);
      elsif ena = "10" then
        -- Matches Verilog: else if (ena == 2'h2) q <= {q[98:0], q[99]};
        -- Rotate left: bits 98:0 shift to 99:1, bit 99 goes to bit 0
        q_reg <= q_reg(98 downto 0) & q_reg(99);
      end if;
      -- For ena = "00" or "11", do nothing (no rotation)
    end if;
  end process;

end architecture rtl;