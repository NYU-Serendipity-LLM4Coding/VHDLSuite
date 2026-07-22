-- (2) DUT implementation (parallel2serial)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity parallel2serial is
  port (
    clk       : in  std_logic;
    rst_n     : in  std_logic;
    d         : in  std_logic_vector(3 downto 0);
    valid_out : out std_logic;
    dout      : out std_logic
  );
end entity parallel2serial;

architecture rtl of parallel2serial is
  signal data : std_logic_vector(3 downto 0) := "0000";
  signal cnt : unsigned(1 downto 0);
  signal valid : std_logic;
  
begin

  -- Output assignments
  dout <= data(3);
  valid_out <= valid;
  
  -- Main process
  main_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      data <= "0000";
      cnt <= "00";
      valid <= '0';
    elsif rising_edge(clk) then
      if cnt = "11" then
        data <= d;
        cnt <= "00";
        valid <= '1';
      else
        cnt <= cnt + 1;
        valid <= '0';
        data <= data(2 downto 0) & data(3);  -- Rotate left
      end if;
    end if;
  end process;
  
end architecture rtl;