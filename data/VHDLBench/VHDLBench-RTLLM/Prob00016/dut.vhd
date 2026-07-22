-- (2) DUT implementation (fixed_point_adder)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fixed_point_adder is
  generic (
    Q : integer := 15;
    N : integer := 32
  );
  port (
    a : in  std_logic_vector(N-1 downto 0);
    b : in  std_logic_vector(N-1 downto 0);
    c : out std_logic_vector(N-1 downto 0)
  );
end entity fixed_point_adder;

architecture rtl of fixed_point_adder is
  signal res : std_logic_vector(N-1 downto 0);
begin

  c <= res;
  
  computation : process(a, b)
    variable a_abs : unsigned(N-2 downto 0);
    variable b_abs : unsigned(N-2 downto 0);
    variable res_abs : unsigned(N-2 downto 0);
  begin
    a_abs := unsigned(a(N-2 downto 0));
    b_abs := unsigned(b(N-2 downto 0));
    
    -- Both negative or both positive
    if a(N-1) = b(N-1) then
      res_abs := a_abs + b_abs;
      res(N-2 downto 0) <= std_logic_vector(res_abs);
      res(N-1) <= a(N-1);
      
    -- a is positive, b is negative
    elsif a(N-1) = '0' and b(N-1) = '1' then
      if a_abs > b_abs then
        res_abs := a_abs - b_abs;
        res(N-2 downto 0) <= std_logic_vector(res_abs);
        res(N-1) <= '0';
      else
        res_abs := b_abs - a_abs;
        res(N-2 downto 0) <= std_logic_vector(res_abs);
        if res_abs = 0 then
          res(N-1) <= '0';
        else
          res(N-1) <= '1';
        end if;
      end if;
      
    -- a is negative, b is positive
    else
      if a_abs > b_abs then
        res_abs := a_abs - b_abs;
        res(N-2 downto 0) <= std_logic_vector(res_abs);
        if res_abs = 0 then
          res(N-1) <= '0';
        else
          res(N-1) <= '1';
        end if;
      else
        res_abs := b_abs - a_abs;
        res(N-2 downto 0) <= std_logic_vector(res_abs);
        res(N-1) <= '0';
      end if;
    end if;
  end process;

end architecture rtl;