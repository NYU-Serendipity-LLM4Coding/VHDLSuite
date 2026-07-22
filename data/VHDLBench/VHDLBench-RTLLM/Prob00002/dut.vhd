library ieee;
use ieee.std_logic_1164.all;

-- ========== 1-bit Full Adder (Base Component) ==========
entity add1 is
  port (
    a   : in  std_logic;
    b   : in  std_logic;
    Cin : in  std_logic;
    y   : out std_logic;
    Co  : out std_logic
  );
end entity;

architecture rtl of add1 is
begin
  -- Sum output: y = a XOR b XOR Cin
  y <= ((not a) and (not b) and Cin) or 
       ((not a) and b and (not Cin)) or 
       (a and (not b) and (not Cin)) or 
       (a and b and Cin);
  
  -- Carry output: Co = majority(a, b, Cin)
  Co <= ((not a) and b and Cin) or 
        (a and (not b) and Cin) or 
        (a and b and (not Cin)) or 
        (a and b and Cin);
end architecture;

-- ========== 2-bit Adder ==========
library ieee;
use ieee.std_logic_1164.all;

entity add2 is
  port (
    a   : in  std_logic_vector(1 downto 0);
    b   : in  std_logic_vector(1 downto 0);
    Cin : in  std_logic;
    y   : out std_logic_vector(1 downto 0);
    Co  : out std_logic
  );
end entity;

architecture rtl of add2 is
  signal Co_temp : std_logic;
begin
  -- Bit 0
  add1_inst2 : entity work.add1
    port map (
      a   => a(0),
      b   => b(0),
      Cin => Cin,
      y   => y(0),
      Co  => Co_temp
    );
  
  -- Bit 1
  add1_inst1 : entity work.add1
    port map (
      a   => a(1),
      b   => b(1),
      Cin => Co_temp,
      y   => y(1),
      Co  => Co
    );
end architecture;

-- ========== 4-bit Adder ==========
library ieee;
use ieee.std_logic_1164.all;

entity add4 is
  port (
    a   : in  std_logic_vector(3 downto 0);
    b   : in  std_logic_vector(3 downto 0);
    Cin : in  std_logic;
    y   : out std_logic_vector(3 downto 0);
    Co  : out std_logic
  );
end entity;

architecture rtl of add4 is
  signal Co_temp : std_logic;
begin
  -- Lower 2 bits
  add2_inst2 : entity work.add2
    port map (
      a   => a(1 downto 0),
      b   => b(1 downto 0),
      Cin => Cin,
      y   => y(1 downto 0),
      Co  => Co_temp
    );
  
  -- Upper 2 bits
  add2_inst1 : entity work.add2
    port map (
      a   => a(3 downto 2),
      b   => b(3 downto 2),
      Cin => Co_temp,
      y   => y(3 downto 2),
      Co  => Co
    );
end architecture;

-- ========== 8-bit Adder ==========
library ieee;
use ieee.std_logic_1164.all;

entity add8 is
  port (
    a   : in  std_logic_vector(7 downto 0);
    b   : in  std_logic_vector(7 downto 0);
    Cin : in  std_logic;
    y   : out std_logic_vector(7 downto 0);
    Co  : out std_logic
  );
end entity;

architecture rtl of add8 is
  signal Co_temp : std_logic;
begin
  -- Lower 4 bits
  add4_inst2 : entity work.add4
    port map (
      a   => a(3 downto 0),
      b   => b(3 downto 0),
      Cin => Cin,
      y   => y(3 downto 0),
      Co  => Co_temp
    );
  
  -- Upper 4 bits
  add4_inst1 : entity work.add4
    port map (
      a   => a(7 downto 4),
      b   => b(7 downto 4),
      Cin => Co_temp,
      y   => y(7 downto 4),
      Co  => Co
    );
end architecture;

-- ========== Top Level: 16-bit Adder ==========
library ieee;
use ieee.std_logic_1164.all;

entity adder_16bit is
  port (
    a   : in  std_logic_vector(15 downto 0);
    b   : in  std_logic_vector(15 downto 0);
    Cin : in  std_logic;
    y   : out std_logic_vector(15 downto 0);
    Co  : out std_logic
  );
end entity;

architecture rtl of adder_16bit is
  signal Co_temp : std_logic;
begin
  -- Lower 8 bits (with Cin input)
  add8_inst2 : entity work.add8
    port map (
      a   => a(7 downto 0),
      b   => b(7 downto 0),
      Cin => Cin,
      y   => y(7 downto 0),
      Co  => Co_temp
    );
  
  -- Upper 8 bits (with carry from lower 8 bits)
  add8_inst1 : entity work.add8
    port map (
      a   => a(15 downto 8),
      b   => b(15 downto 8),
      Cin => Co_temp,
      y   => y(15 downto 8),
      Co  => Co
    );
end architecture;