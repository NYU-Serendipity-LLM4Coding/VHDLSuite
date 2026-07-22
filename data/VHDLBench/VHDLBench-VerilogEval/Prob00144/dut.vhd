-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement Conway's Game of Life on 16x16 toroidal grid

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk  : in  std_logic;
    load : in  std_logic;
    data : in  std_logic_vector(255 downto 0);
    q    : out std_logic_vector(255 downto 0)
  );
end entity TopModule;

architecture rtl of TopModule is
  signal q_reg : std_logic_vector(255 downto 0) := (others => '0');
  type padded_array_t is array(0 to 17) of std_logic_vector(17 downto 0);
  signal q_pad : padded_array_t;
begin

  q <= q_reg;
  
  padding_logic : process(q_reg)
  begin
    for i in 0 to 15 loop
      q_pad(i+1)(16 downto 1) <= q_reg(16*i+15 downto 16*i);
    end loop;
    
    q_pad(1)(16 downto 1) <= q_reg(16*15+15 downto 16*15);
    q_pad(17)(16 downto 1) <= q_reg(15 downto 0);
    
    for i in 0 to 17 loop
      q_pad(i)(0)  <= q_pad(i)(16);
      q_pad(i)(17) <= q_pad(i)(1);
    end loop;
  end process;
  
  game_logic : process(clk)
    variable neighbor_sum : unsigned(2 downto 0);
    variable current_cell : std_logic;
    variable combined : unsigned(2 downto 0);
  begin
    if rising_edge(clk) then
      for i in 0 to 15 loop
        for j in 0 to 15 loop
          neighbor_sum := 
            resize(unsigned'(0 => q_pad(i)(j)), 3) +
            resize(unsigned'(0 => q_pad(i)(j+1)), 3) +
            resize(unsigned'(0 => q_pad(i)(j+2)), 3) +
            resize(unsigned'(0 => q_pad(i+1)(j)), 3) +
            resize(unsigned'(0 => q_pad(i+1)(j+2)), 3) +
            resize(unsigned'(0 => q_pad(i+2)(j)), 3) +
            resize(unsigned'(0 => q_pad(i+2)(j+1)), 3) +
            resize(unsigned'(0 => q_pad(i+2)(j+2)), 3);
          
          current_cell := q_reg(i*16+j);
          
          combined := (neighbor_sum and "111") or resize(unsigned'(0 => current_cell), 3);
          
          if combined = "011" then
            q_reg(i*16+j) <= '1';
          else
            q_reg(i*16+j) <= '0';
          end if;
        end loop;
      end loop;
      
      if load = '1' then
        q_reg <= data;
      end if;
    end if;
  end process;

end architecture rtl;