library ieee;
use ieee.std_logic_1164.all;

entity LFSR is
  port (
    lfsr_out : out std_logic_vector(3 downto 0);
    clk      : in  std_logic;
    rst      : in  std_logic
  );
end entity LFSR;

architecture rtl of LFSR is
  signal out_reg : std_logic_vector(3 downto 0);
  signal feedback : std_logic;
begin
  -- Feedback calculation: ~(out[3] ^ out[2])
  feedback <= not (out_reg(3) xor out_reg(2));
  
  -- LFSR shift register process
  process(clk, rst)
  begin
    if rst = '1' then
      out_reg <= (others => '0');
    elsif rising_edge(clk) then
      -- Shift left and insert feedback at LSB: {out[2:0], feedback}
      out_reg <= out_reg(2 downto 0) & feedback;
    end if;
  end process;
  
  -- Output assignment
  lfsr_out <= out_reg;
end architecture rtl;