library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_8bit is
  port (
    a    : in  std_logic_vector(7 downto 0);
    b    : in  std_logic_vector(7 downto 0);
    cin  : in  std_logic;
    sum  : out std_logic_vector(7 downto 0);
    cout : out std_logic
  );
end entity adder_8bit;

architecture rtl of adder_8bit is
  
  -- Full adder component
  component full_adder is
    port (
      a    : in  std_logic;
      b    : in  std_logic;
      cin  : in  std_logic;
      sum  : out std_logic;
      cout : out std_logic
    );
  end component;
  
  -- Internal carry chain (9 bits: cin + 8 intermediate carries)
  signal c : std_logic_vector(8 downto 0);
  
begin

  -- Assign input carry
  c(0) <= cin;
  
  -- Instantiate 8 full adders
  FA0 : full_adder port map (a => a(0), b => b(0), cin => c(0), sum => sum(0), cout => c(1));
  FA1 : full_adder port map (a => a(1), b => b(1), cin => c(1), sum => sum(1), cout => c(2));
  FA2 : full_adder port map (a => a(2), b => b(2), cin => c(2), sum => sum(2), cout => c(3));
  FA3 : full_adder port map (a => a(3), b => b(3), cin => c(3), sum => sum(3), cout => c(4));
  FA4 : full_adder port map (a => a(4), b => b(4), cin => c(4), sum => sum(4), cout => c(5));
  FA5 : full_adder port map (a => a(5), b => b(5), cin => c(5), sum => sum(5), cout => c(6));
  FA6 : full_adder port map (a => a(6), b => b(6), cin => c(6), sum => sum(6), cout => c(7));
  FA7 : full_adder port map (a => a(7), b => b(7), cin => c(7), sum => sum(7), cout => c(8));
  
  -- Assign output carry
  cout <= c(8);

end architecture rtl;

-- Full adder module
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity full_adder is
  port (
    a    : in  std_logic;
    b    : in  std_logic;
    cin  : in  std_logic;
    sum  : out std_logic;
    cout : out std_logic
  );
end entity full_adder;

architecture rtl of full_adder is
  signal temp : unsigned(1 downto 0);
begin
  temp <= resize(unsigned'(""&a), 2) + resize(unsigned'(""&b), 2) + resize(unsigned'(""&cin), 2);
  cout <= temp(1);
  sum  <= temp(0);
end architecture rtl;