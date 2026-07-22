-- (2) DUT implementation (RAM Module)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
  port (
    clk        : in  std_logic;
    rst_n      : in  std_logic;
    write_en   : in  std_logic;
    write_addr : in  std_logic_vector(7 downto 0);
    write_data : in  std_logic_vector(5 downto 0);
    read_en    : in  std_logic;
    read_addr  : in  std_logic_vector(7 downto 0);
    read_data  : out std_logic_vector(5 downto 0)
  );
end entity RAM;

architecture rtl of RAM is
  -- RAM array: 8 locations, each 6 bits wide
  type ram_type is array (0 to 7) of std_logic_vector(5 downto 0);
  signal RAM_array : ram_type := (others => (others => '0'));
  
begin

  -- Write Operation
  write_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      -- Initialize all RAM locations to 0 on reset
      for i in 0 to 7 loop
        RAM_array(i) <= (others => '0');
      end loop;
    elsif rising_edge(clk) then
      if write_en = '1' then
        -- Write data to RAM at specified address (use only lower 3 bits)
        RAM_array(to_integer(unsigned(write_addr(2 downto 0)))) <= write_data;
      end if;
    end if;
  end process;
  
  -- Read Operation
  read_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      read_data <= (others => '0');
    elsif rising_edge(clk) then
      if read_en = '1' then
        -- Read data from RAM at specified address (use only lower 3 bits)
        read_data <= RAM_array(to_integer(unsigned(read_addr(2 downto 0))));
      else
        -- Clear read_data when read_en is not active
        read_data <= (others => '0');
      end if;
    end if;
  end process;
  
end architecture rtl;