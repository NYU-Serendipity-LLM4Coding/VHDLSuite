-- (2) DUT implementation (TopModule)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity square_wave is
  port (
    clk      : in  std_logic;
    freq     : in  std_logic_vector(7 downto 0);
    wave_out : out std_logic
  );
end entity square_wave;

architecture rtl of square_wave is
  signal count : unsigned(7 downto 0) := (others => '0');
  signal wave_out_reg : std_logic := '0';
  
begin

  -- Output assignment
  wave_out <= wave_out_reg;
  
  -- Counter and wave generation process
  wave_gen_proc : process(clk)
  begin
    if rising_edge(clk) then
      -- Check if count reached (freq - 1)
      if count = unsigned(freq) - 1 then
        count <= (others => '0');
        wave_out_reg <= not wave_out_reg;  -- Toggle the output
      else
        count <= count + 1;
      end if;
    end if;
  end process;
  
end architecture rtl;