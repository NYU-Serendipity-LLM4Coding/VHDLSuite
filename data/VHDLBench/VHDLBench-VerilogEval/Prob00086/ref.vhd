-- (3) Reference implementation (RefModule)
-- Reference Module: 5-bit Galois LFSR
-- Taps at bit positions 5 (q[4]) and 3 (q[2])
-- Synchronous reset to 5'h1 (binary: 00001)
-- Combinational logic computes next state, sequential logic registers it

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    q     : out std_logic_vector(4 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  signal q_reg  : std_logic_vector(4 downto 0) := "00001";  -- Matches initial reset value
  signal q_next : std_logic_vector(4 downto 0);
begin
  
  q <= q_reg;
  
  -- Combinational logic for next state
  -- Matches Verilog: always @(q) begin
  --   q_next = q[4:1];
  --   q_next[4] = q[0];
  --   q_next[2] ^= q[0];
  -- end
  process(q_reg)
  begin
    -- Shift right: q_next[3:0] = q[4:1]
    q_next(3 downto 0) <= q_reg(4 downto 1);
    
    -- Feedback: q_next[4] = q[0]
    q_next(4) <= q_reg(0);
    
    -- XOR tap at position 2: q_next[2] ^= q[0]
    q_next(2) <= q_reg(3) xor q_reg(0);
  end process;
  
  -- Sequential logic
  -- Matches Verilog: always @(posedge clk) begin
  --   if (reset) q <= 5'h1;
  --   else q <= q_next;
  -- end
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        q_reg <= "00001";  -- 5'h1
      else
        q_reg <= q_next;
      end if;
    end if;
  end process;

end architecture rtl;