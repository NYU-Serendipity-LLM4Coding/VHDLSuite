-- (3) Reference implementation (RefModule)
-- Reference Module: 32-bit Galois LFSR
-- Linear Feedback Shift Register with taps at positions 32, 22, 2, 1
-- Shifts right with XOR feedback from LSB (q[0])
-- Synchronous active-high reset to 32'h1

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    q     : out std_logic_vector(31 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  -- Register to hold current state
  signal q_reg : std_logic_vector(31 downto 0) := (0 => '1', others => '0');
  
begin
  
  q <= q_reg;
  
  -- Matches Verilog: always @(posedge clk)
  process(clk)
    variable q_next : std_logic_vector(31 downto 0);
  begin
    if rising_edge(clk) then
      if reset = '1' then
        -- Matches Verilog: q <= 32'h1;
        q_reg <= (0 => '1', others => '0');
      else
        -- Compute next state (matches Verilog combinational always@(q) block)
        -- q_next = q[31:1]; (right shift)
        q_next := '0' & q_reg(31 downto 1);
        
        -- q_next[31] = q[0]; (wrap around from LSB)
        q_next(31) := q_reg(0);
        
        -- Apply taps (XOR with q[0])
        -- q_next[21] ^= q[0];
        q_next(21) := q_next(21) xor q_reg(0);
        
        -- q_next[1] ^= q[0];
        q_next(1) := q_next(1) xor q_reg(0);
        
        -- q_next[0] ^= q[0];
        q_next(0) := q_next(0) xor q_reg(0);
        
        -- Update register
        q_reg <= q_next;
      end if;
    end if;
  end process;

end architecture rtl;