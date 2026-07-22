library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ROM is
  port (
    addr : in  std_logic_vector(7 downto 0);   -- 8-bit Address input
    dout : out std_logic_vector(15 downto 0)   -- 16-bit Data output
  );
end entity ROM;

architecture rtl of ROM is
  -- Declare a memory array of 256 locations, each 16 bits wide
  type mem_array_t is array (0 to 255) of std_logic_vector(15 downto 0);
  
  -- Initialize ROM with data using aggregate assignment
  constant mem : mem_array_t := (
    0 => x"A0A0",
    1 => x"B1B1",
    2 => x"C2C2",
    3 => x"D3D3",
    others => (others => '0')
  );
  
begin

  -- Combinational logic: Read data from the ROM at the specified address
  dout <= mem(to_integer(unsigned(addr)));

end architecture rtl;