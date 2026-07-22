-- (2) DUT implementation (barrel_shifter)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- 2-to-1 Multiplexer
entity mux2X1 is
  port (
    in0 : in  std_logic;
    in1 : in  std_logic;
    sel : in  std_logic;
    output : out std_logic
  );
end entity mux2X1;

architecture rtl of mux2X1 is
begin
  output <= in1 when sel = '1' else in0;
end architecture rtl;

-- Barrel Shifter
library ieee;
use ieee.std_logic_1164.all;

entity barrel_shifter is
  port (
    input_data  : in  std_logic_vector(7 downto 0);
    ctrl        : in  std_logic_vector(2 downto 0);
    output_data : out std_logic_vector(7 downto 0)
  );
end entity barrel_shifter;

architecture rtl of barrel_shifter is
  signal x : std_logic_vector(7 downto 0);
  signal y : std_logic_vector(7 downto 0);
  
  component mux2X1 is
    port (
      in0 : in  std_logic;
      in1 : in  std_logic;
      sel : in  std_logic;
      output : out std_logic
    );
  end component;
  
begin

  -- ========== Stage 1: 4-bit shift right ==========
  ins_17 : mux2X1 port map (in0 => input_data(7), in1 => '0',          sel => ctrl(2), output => x(7));
  ins_16 : mux2X1 port map (in0 => input_data(6), in1 => '0',          sel => ctrl(2), output => x(6));
  ins_15 : mux2X1 port map (in0 => input_data(5), in1 => '0',          sel => ctrl(2), output => x(5));
  ins_14 : mux2X1 port map (in0 => input_data(4), in1 => '0',          sel => ctrl(2), output => x(4));
  ins_13 : mux2X1 port map (in0 => input_data(3), in1 => input_data(7), sel => ctrl(2), output => x(3));
  ins_12 : mux2X1 port map (in0 => input_data(2), in1 => input_data(6), sel => ctrl(2), output => x(2));
  ins_11 : mux2X1 port map (in0 => input_data(1), in1 => input_data(5), sel => ctrl(2), output => x(1));
  ins_10 : mux2X1 port map (in0 => input_data(0), in1 => input_data(4), sel => ctrl(2), output => x(0));
  
  -- ========== Stage 2: 2-bit shift right ==========
  ins_27 : mux2X1 port map (in0 => x(7), in1 => '0',  sel => ctrl(1), output => y(7));
  ins_26 : mux2X1 port map (in0 => x(6), in1 => '0',  sel => ctrl(1), output => y(6));
  ins_25 : mux2X1 port map (in0 => x(5), in1 => x(7), sel => ctrl(1), output => y(5));
  ins_24 : mux2X1 port map (in0 => x(4), in1 => x(6), sel => ctrl(1), output => y(4));
  ins_23 : mux2X1 port map (in0 => x(3), in1 => x(5), sel => ctrl(1), output => y(3));
  ins_22 : mux2X1 port map (in0 => x(2), in1 => x(4), sel => ctrl(1), output => y(2));
  ins_21 : mux2X1 port map (in0 => x(1), in1 => x(3), sel => ctrl(1), output => y(1));
  ins_20 : mux2X1 port map (in0 => x(0), in1 => x(2), sel => ctrl(1), output => y(0));
  
  -- ========== Stage 3: 1-bit shift right ==========
  ins_07 : mux2X1 port map (in0 => y(7), in1 => '0',  sel => ctrl(0), output => output_data(7));
  ins_06 : mux2X1 port map (in0 => y(6), in1 => y(7), sel => ctrl(0), output => output_data(6));
  ins_05 : mux2X1 port map (in0 => y(5), in1 => y(6), sel => ctrl(0), output => output_data(5));
  ins_04 : mux2X1 port map (in0 => y(4), in1 => y(5), sel => ctrl(0), output => output_data(4));
  ins_03 : mux2X1 port map (in0 => y(3), in1 => y(4), sel => ctrl(0), output => output_data(3));
  ins_02 : mux2X1 port map (in0 => y(2), in1 => y(3), sel => ctrl(0), output => output_data(2));
  ins_01 : mux2X1 port map (in0 => y(1), in1 => y(2), sel => ctrl(0), output => output_data(1));
  ins_00 : mux2X1 port map (in0 => y(0), in1 => y(1), sel => ctrl(0), output => output_data(0));

end architecture rtl;