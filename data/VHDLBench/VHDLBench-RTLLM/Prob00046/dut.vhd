library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pe is
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    a   : in  std_logic_vector(31 downto 0);
    b   : in  std_logic_vector(31 downto 0);
    c   : out std_logic_vector(31 downto 0)
  );
end entity pe;

architecture rtl of pe is
  signal cc : unsigned(31 downto 0) := (others => '0');
begin

  -- Output assignment
  c <= std_logic_vector(cc);
  
  -- MAC accumulator process
  mac_proc : process(clk, rst)
  begin
    if rst = '1' then
      cc <= (others => '0');
    elsif rising_edge(clk) then
      -- ✅ 使用 resize 截断乘法结果到32位
      cc <= cc + resize(unsigned(a) * unsigned(b), 32);
    end if;
  end process;

end architecture rtl;