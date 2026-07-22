-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement state machine logic functions Y0 and z

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk : in  std_logic;
    x   : in  std_logic;
    y   : in  std_logic_vector(2 downto 0);
    Y0  : out std_logic;
    z   : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal Y0_comb : std_logic;
  signal z_comb  : std_logic;
begin
  
  Y0 <= Y0_comb;
  z  <= z_comb;
  
  process(x, y)
    variable y_x : std_logic_vector(3 downto 0);
  begin
    y_x := y & x;
    
    case y_x is
      when "0000" => Y0_comb <= '0';
      when "0001" => Y0_comb <= '1';
      when "0010" => Y0_comb <= '1';
      when "0011" => Y0_comb <= '0';
      when "0100" => Y0_comb <= '0';
      when "0101" => Y0_comb <= '1';
      when "0110" => Y0_comb <= '1';
      when "0111" => Y0_comb <= '0';
      when "1000" => Y0_comb <= '1';
      when "1001" => Y0_comb <= '0';
      when others => Y0_comb <= 'X';
    end case;
    
    case y is
      when "000"  => z_comb <= '0';
      when "001"  => z_comb <= '0';
      when "010"  => z_comb <= '0';
      when "011"  => z_comb <= '1';
      when "100"  => z_comb <= '1';
      when others => z_comb <= 'X';
    end case;
  end process;

end architecture rtl;