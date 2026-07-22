-- (2) DUT implementation (fixed_point_subtractor)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fixed_point_subtractor is
  generic (
    Q : integer := 15;
    N : integer := 32
  );
  port (
    a : in  std_logic_vector(N-1 downto 0);
    b : in  std_logic_vector(N-1 downto 0);
    c : out std_logic_vector(N-1 downto 0)
  );
end entity fixed_point_subtractor;

architecture rtl of fixed_point_subtractor is
  signal res : std_logic_vector(N-1 downto 0);
begin

  c <= res;
  
  subtract_proc : process(a, b)
    variable a_mag : unsigned(N-2 downto 0);
    variable b_mag : unsigned(N-2 downto 0);
    variable sum_mag : unsigned(N-2 downto 0);
  begin
    a_mag := unsigned(a(N-2 downto 0));
    b_mag := unsigned(b(N-2 downto 0));
    
    -- Both negative or both positive
    if a(N-1) = b(N-1) then
      res(N-2 downto 0) <= std_logic_vector(a_mag - b_mag);
      res(N-1) <= a(N-1);
    
    -- a positive, b negative
    elsif a(N-1) = '0' and b(N-1) = '1' then
      if a_mag > b_mag then
        res(N-2 downto 0) <= std_logic_vector(a_mag + b_mag);
        res(N-1) <= '0';
      else
        sum_mag := b_mag + a_mag;
        res(N-2 downto 0) <= std_logic_vector(sum_mag);
        if sum_mag = 0 then
          res(N-1) <= '0';
        else
          res(N-1) <= '1';
        end if;
      end if;
    
    -- a negative, b positive
    else
      if a_mag > b_mag then
        sum_mag := a_mag + b_mag;
        res(N-2 downto 0) <= std_logic_vector(sum_mag);
        if sum_mag = 0 then
          res(N-1) <= '0';
        else
          res(N-1) <= '1';
        end if;
      else
        res(N-2 downto 0) <= std_logic_vector(b_mag + a_mag);
        res(N-1) <= '0';
      end if;
    end if;
    
  end process;

end architecture rtl;