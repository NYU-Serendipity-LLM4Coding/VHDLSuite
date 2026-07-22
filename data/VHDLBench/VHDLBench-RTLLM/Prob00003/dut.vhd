library ieee;
use ieee.std_logic_1164.all;

-- ========== Basic adder Module (lowest level) ==========
entity adder is
  port (
    X    : in  std_logic;
    Y    : in  std_logic;
    Cin  : in  std_logic;
    F    : out std_logic;
    Cout : out std_logic
  );
end entity;

architecture rtl of adder is
begin
  F    <= X xor Y xor Cin;
  Cout <= ((X xor Y) and Cin) or (X and Y);
end architecture;

-- ========== CLA Module ==========
library ieee;
use ieee.std_logic_1164.all;

entity CLA is
  port (
    c0, g1, g2, g3, g4, p1, p2, p3, p4 : in  std_logic;
    c1, c2, c3, c4                     : out std_logic
  );
end entity;

architecture rtl of CLA is
begin
  c1 <= g1 or (p1 and c0);
  c2 <= g2 or (p2 and g1) or (p2 and p1 and c0);
  c3 <= g3 or (p3 and g2) or (p3 and p2 and g1) or (p3 and p2 and p1 and c0);
  c4 <= g4 or (p4 and g3) or (p4 and p3 and g2) or (p4 and p3 and p2 and g1) or (p4 and p3 and p2 and p1 and c0);
end architecture;

-- ========== adder_4 Module ==========
library ieee;
use ieee.std_logic_1164.all;

entity adder_4 is
  port (
    x  : in  std_logic_vector(3 downto 0);
    y  : in  std_logic_vector(3 downto 0);
    c0 : in  std_logic;
    c4 : out std_logic;
    F  : out std_logic_vector(3 downto 0);
    Gm : out std_logic;
    Pm : out std_logic
  );
end entity;

architecture rtl of adder_4 is
  signal p1, p2, p3, p4, g1, g2, g3, g4 : std_logic;
  signal c1, c2, c3 : std_logic;
begin

  adder1 : entity work.adder
    port map (
      X    => x(0),
      Y    => y(0),
      Cin  => c0,
      F    => F(0),
      Cout => open
    );

  adder2 : entity work.adder
    port map (
      X    => x(1),
      Y    => y(1),
      Cin  => c1,
      F    => F(1),
      Cout => open
    );

  adder3 : entity work.adder
    port map (
      X    => x(2),
      Y    => y(2),
      Cin  => c2,
      F    => F(2),
      Cout => open
    );

  adder4 : entity work.adder
    port map (
      X    => x(3),
      Y    => y(3),
      Cin  => c3,
      F    => F(3),
      Cout => open
    );

  CLA_inst : entity work.CLA
    port map (
      c0 => c0,
      c1 => c1,
      c2 => c2,
      c3 => c3,
      c4 => c4,
      p1 => p1,
      p2 => p2,
      p3 => p3,
      p4 => p4,
      g1 => g1,
      g2 => g2,
      g3 => g3,
      g4 => g4
    );

  p1 <= x(0) xor y(0);
  p2 <= x(1) xor y(1);
  p3 <= x(2) xor y(2);
  p4 <= x(3) xor y(3);

  g1 <= x(0) and y(0);
  g2 <= x(1) and y(1);
  g3 <= x(2) and y(2);
  g4 <= x(3) and y(3);

  Pm <= p1 and p2 and p3 and p4;
  Gm <= g4 or (p4 and g3) or (p4 and p3 and g2) or (p4 and p3 and p2 and g1);

end architecture;

-- ========== CLA_16 Module ==========
library ieee;
use ieee.std_logic_1164.all;

entity CLA_16 is
  port (
    A  : in  std_logic_vector(15 downto 0);
    B  : in  std_logic_vector(15 downto 0);
    c0 : in  std_logic;
    S  : out std_logic_vector(15 downto 0);
    px : out std_logic;
    gx : out std_logic
  );
end entity;

architecture rtl of CLA_16 is
  signal c4, c8, c12 : std_logic;
  signal Pm1, Gm1, Pm2, Gm2, Pm3, Gm3, Pm4, Gm4 : std_logic;
begin

  adder1 : entity work.adder_4
    port map (
      x  => A(3 downto 0),
      y  => B(3 downto 0),
      c0 => c0,
      c4 => open,
      F  => S(3 downto 0),
      Gm => Gm1,
      Pm => Pm1
    );

  adder2 : entity work.adder_4
    port map (
      x  => A(7 downto 4),
      y  => B(7 downto 4),
      c0 => c4,
      c4 => open,
      F  => S(7 downto 4),
      Gm => Gm2,
      Pm => Pm2
    );

  adder3 : entity work.adder_4
    port map (
      x  => A(11 downto 8),
      y  => B(11 downto 8),
      c0 => c8,
      c4 => open,
      F  => S(11 downto 8),
      Gm => Gm3,
      Pm => Pm3
    );

  adder4 : entity work.adder_4
    port map (
      x  => A(15 downto 12),
      y  => B(15 downto 12),
      c0 => c12,
      c4 => open,
      F  => S(15 downto 12),
      Gm => Gm4,
      Pm => Pm4
    );

  c4  <= Gm1 or (Pm1 and c0);
  c8  <= Gm2 or (Pm2 and Gm1) or (Pm2 and Pm1 and c0);
  c12 <= Gm3 or (Pm3 and Gm2) or (Pm3 and Pm2 and Gm1) or (Pm3 and Pm2 and Pm1 and c0);

  px <= Pm1 and Pm2 and Pm3 and Pm4;
  gx <= Gm4 or (Pm4 and Gm3) or (Pm4 and Pm3 and Gm2) or (Pm4 and Pm3 and Pm2 and Gm1);

end architecture;

-- ========== Top Module adder_32bit ==========
library ieee;
use ieee.std_logic_1164.all;

entity adder_32bit is
  port (
    A   : in  std_logic_vector(31 downto 0);
    B   : in  std_logic_vector(31 downto 0);
    S   : out std_logic_vector(31 downto 0);
    C32 : out std_logic
  );
end entity;

architecture rtl of adder_32bit is
  signal px1, gx1, px2, gx2 : std_logic;
  signal c16 : std_logic;
begin

  CLA1 : entity work.CLA_16
    port map (
      A  => A(15 downto 0),
      B  => B(15 downto 0),
      c0 => '0',
      S  => S(15 downto 0),
      px => px1,
      gx => gx1
    );

  CLA2 : entity work.CLA_16
    port map (
      A  => A(31 downto 16),
      B  => B(31 downto 16),
      c0 => c16,
      S  => S(31 downto 16),
      px => px2,
      gx => gx2
    );

  c16 <= gx1 or (px1 and '0');
  C32 <= gx2 or (px2 and c16);

end architecture;