-- (2) DUT implementation (instr_reg)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instr_reg is
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    fetch : in  std_logic_vector(1 downto 0);
    data  : in  std_logic_vector(7 downto 0);
    ins   : out std_logic_vector(2 downto 0);
    ad1   : out std_logic_vector(4 downto 0);
    ad2   : out std_logic_vector(7 downto 0)
  );
end entity instr_reg;

architecture rtl of instr_reg is
  signal ins_p1 : std_logic_vector(7 downto 0);
  signal ins_p2 : std_logic_vector(7 downto 0);
  
begin

  -- Register process
  reg_proc : process(clk, rst)
  begin
    if rst = '0' then
      ins_p1 <= (others => '0');
      ins_p2 <= (others => '0');
    elsif rising_edge(clk) then
      if fetch = "01" then
        -- Fetch operation 1, from REG
        ins_p1 <= data;
        -- ins_p2 retains its value
      elsif fetch = "10" then
        -- Fetch operation 2, from RAM/ROM
        ins_p2 <= data;
        -- ins_p1 retains its value
      end if;
      -- If fetch is neither "01" nor "10", both registers retain their values
    end if;
  end process;
  
  -- Output assignments
  ins <= ins_p1(7 downto 5);  -- High 3 bits, instructions
  ad1 <= ins_p1(4 downto 0);  -- Low 5 bits, register address
  ad2 <= ins_p2;              -- Full 8-bit data from second source
  
end architecture rtl;