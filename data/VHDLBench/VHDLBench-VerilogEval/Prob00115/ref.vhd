-- (3) Reference implementation (RefModule)
-- Reference Module: 64-bit Arithmetic Shift Register
-- Supports load, left/right shift by 1 or 8 bits
-- Arithmetic right shift preserves sign bit

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk    : in  std_logic;
    load   : in  std_logic;
    ena    : in  std_logic;
    amount : in  std_logic_vector(1 downto 0);
    data   : in  std_logic_vector(63 downto 0);
    q      : out std_logic_vector(63 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  signal q_reg : std_logic_vector(63 downto 0) := (others => '0');
begin
  
  q <= q_reg;
  
  -- Matches Verilog: always @(posedge clk) begin ... end
  process(clk)
  begin
    if rising_edge(clk) then
      if load = '1' then
        -- Load data
        q_reg <= data;
      elsif ena = '1' then
        case amount is
          when "00" =>
            -- Shift left by 1: {q[62:0], 1'b0}
            q_reg <= q_reg(62 downto 0) & '0';
          
          when "01" =>
            -- Shift left by 8: {q[55:0], 8'b0}
            q_reg <= q_reg(55 downto 0) & "00000000";
          
          when "10" =>
            -- Arithmetic right shift by 1: {q[63], q[63:1]}
            q_reg <= q_reg(63) & q_reg(63 downto 1);
          
          when "11" =>
            -- Arithmetic right shift by 8: {{8{q[63]}}, q[63:8]}
            q_reg <= (63 downto 56 => q_reg(63)) & q_reg(63 downto 8);
          
          when others =>
            q_reg <= (others => 'X');
        end case;
      end if;
    end if;
  end process;

end architecture rtl;