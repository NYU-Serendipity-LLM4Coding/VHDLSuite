-- (3) Reference implementation (RefModule)
-- Reference Module: State Machine Logic Functions
-- Implements Y0 and z based on state table using case statements
-- Y0 depends on {y[2:0], x}, z depends only on y[2:0]

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk : in  std_logic;
    x   : in  std_logic;
    y   : in  std_logic_vector(2 downto 0);
    Y0  : out std_logic;
    z   : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  signal Y0_comb : std_logic;
  signal z_comb  : std_logic;
begin
  
  Y0 <= Y0_comb;
  z  <= z_comb;
  
  -- Matches Verilog: always_comb
  -- Combinational process for Y0 and z
  process(x, y)
    variable y_x : std_logic_vector(3 downto 0);
  begin
    -- Concatenate {y[2:0], x} for Y0 case statement
    y_x := y & x;
    
    -- Case statement for Y0
    -- Matches Verilog: case ({y[2:0], x})
    case y_x is
      when "0000" => Y0_comb <= '0';  -- 4'h0
      when "0001" => Y0_comb <= '1';  -- 4'h1
      when "0010" => Y0_comb <= '1';  -- 4'h2
      when "0011" => Y0_comb <= '0';  -- 4'h3
      when "0100" => Y0_comb <= '0';  -- 4'h4
      when "0101" => Y0_comb <= '1';  -- 4'h5
      when "0110" => Y0_comb <= '1';  -- 4'h6
      when "0111" => Y0_comb <= '0';  -- 4'h7
      when "1000" => Y0_comb <= '1';  -- 4'h8
      when "1001" => Y0_comb <= '0';  -- 4'h9
      when others => Y0_comb <= 'X';  -- default: 1'bx
    end case;
    
    -- Case statement for z
    -- Matches Verilog: case (y[2:0])
    case y is
      when "000"  => z_comb <= '0';  -- 3'h0
      when "001"  => z_comb <= '0';  -- 3'h1
      when "010"  => z_comb <= '0';  -- 3'h2
      when "011"  => z_comb <= '1';  -- 3'h3
      when "100"  => z_comb <= '1';  -- 3'h4
      when others => z_comb <= 'X';  -- default: 1'bx
    end case;
  end process;

end architecture rtl;