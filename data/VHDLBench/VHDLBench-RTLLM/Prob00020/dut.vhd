-- (2) DUT implementation (TopModule)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_12 is
  port (
    rst_n       : in  std_logic;
    clk         : in  std_logic;
    valid_count : in  std_logic;
    out_port    : out std_logic_vector(3 downto 0)
  );
end entity counter_12;

architecture rtl of counter_12 is
  signal out_reg : unsigned(3 downto 0);
begin

  counter_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      -- Reset counter to 0
      out_reg <= (others => '0');
    elsif rising_edge(clk) then
      if valid_count = '1' then
        -- Check if counter reached maximum value (11)
        if out_reg = to_unsigned(11, 4) then
          -- Wrap around to 0
          out_reg <= (others => '0');
        else
          -- Increment counter
          out_reg <= out_reg + 1;
        end if;
      else
        -- Pause the count when valid_count is 0
        out_reg <= out_reg;
      end if;
    end if;
  end process;
  
  -- Output assignment
  out_port <= std_logic_vector(out_reg);

end architecture rtl;