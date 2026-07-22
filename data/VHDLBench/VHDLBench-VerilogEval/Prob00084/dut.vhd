-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement 8-bit shift register with 8-to-1 mux

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk    : in  std_logic;
    enable : in  std_logic;
    S      : in  std_logic;
    A      : in  std_logic;
    B      : in  std_logic;
    C      : in  std_logic;
    Z      : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal q    : std_logic_vector(7 downto 0) := (others => '0');
  signal addr : std_logic_vector(2 downto 0);
begin

  addr <= A & B & C;
  
  -- Shift register
  process(clk)
  begin
    if rising_edge(clk) then
      if enable = '1' then
        q <= q(6 downto 0) & S;
      end if;
    end if;
  end process;
  
  -- Multiplexer
  Z <= q(to_integer(unsigned(addr)));

end architecture rtl;