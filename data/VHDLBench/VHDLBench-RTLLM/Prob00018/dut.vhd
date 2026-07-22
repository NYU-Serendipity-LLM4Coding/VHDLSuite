-- (2) DUT implementation (float_multi)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity float_multi is
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    a   : in  std_logic_vector(31 downto 0);
    b   : in  std_logic_vector(31 downto 0);
    z   : out std_logic_vector(31 downto 0)
  );
end entity float_multi;

architecture rtl of float_multi is
  signal counter : unsigned(2 downto 0) := (others => '0');
  
  signal a_mantissa, b_mantissa, z_mantissa : unsigned(23 downto 0) := (others => '0');
  signal a_exponent, b_exponent, z_exponent : signed(9 downto 0) := (others => '0');
  signal a_sign, b_sign, z_sign : std_logic := '0';
  
  signal product : unsigned(49 downto 0) := (others => '0');
  signal guard_bit, round_bit, sticky : std_logic := '0';
  
  signal z_reg : std_logic_vector(31 downto 0) := (others => '0');
  
begin

  z <= z_reg;

  -- Counter process
  counter_proc : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        counter <= (others => '0');
      else
        counter <= counter + 1;
      end if;
    end if;
  end process;
  
  -- Main processing
  main_proc : process(clk)
    variable temp_mantissa : unsigned(23 downto 0);
    variable temp_exponent : signed(9 downto 0);
    variable shift_amount : integer;
  begin
    if rising_edge(clk) then
      
      -- Stage 1: Input extraction
      if counter = "001" then
        a_mantissa <= '0' & unsigned(a(22 downto 0));
        b_mantissa <= '0' & unsigned(b(22 downto 0));
        a_exponent <= signed(resize(unsigned(a(30 downto 23)), 10)) - 127;
        b_exponent <= signed(resize(unsigned(b(30 downto 23)), 10)) - 127;
        a_sign <= a(31);
        b_sign <= b(31);
      end if;
      
      -- Stage 2: Special cases
      if counter = "010" then
        -- NaN check
        if (a_exponent = 128 and a_mantissa(22 downto 0) /= "00000000000000000000000") or 
           (b_exponent = 128 and b_mantissa(22 downto 0) /= "00000000000000000000000") then
          z_reg(31) <= '1';
          z_reg(30 downto 23) <= (others => '1');
          z_reg(22) <= '1';
          z_reg(21 downto 0) <= (others => '0');
        -- Infinity A
        elsif a_exponent = 128 then
          z_reg(31) <= a_sign xor b_sign;
          z_reg(30 downto 23) <= (others => '1');
          z_reg(22 downto 0) <= (others => '0');
          if b_exponent = -127 and b_mantissa(22 downto 0) = "00000000000000000000000" then
            z_reg(31) <= '1';
            z_reg(30 downto 23) <= (others => '1');
            z_reg(22) <= '1';
            z_reg(21 downto 0) <= (others => '0');
          end if;
        -- Infinity B
        elsif b_exponent = 128 then
          z_reg(31) <= a_sign xor b_sign;
          z_reg(30 downto 23) <= (others => '1');
          z_reg(22 downto 0) <= (others => '0');
          if a_exponent = -127 and a_mantissa(22 downto 0) = "00000000000000000000000" then
            z_reg(31) <= '1';
            z_reg(30 downto 23) <= (others => '1');
            z_reg(22) <= '1';
            z_reg(21 downto 0) <= (others => '0');
          end if;
        -- Zero A
        elsif a_exponent = -127 and a_mantissa(22 downto 0) = "00000000000000000000000" then
          z_reg(31) <= a_sign xor b_sign;
          z_reg(30 downto 0) <= (others => '0');
        -- Zero B
        elsif b_exponent = -127 and b_mantissa(22 downto 0) = "00000000000000000000000" then
          z_reg(31) <= a_sign xor b_sign;
          z_reg(30 downto 0) <= (others => '0');
        -- Normal case denormalization
        else
          if a_exponent = -127 then
            a_exponent <= to_signed(-126, 10);
          else
            a_mantissa(23) <= '1';
          end if;
          
          if b_exponent = -127 then
            b_exponent <= to_signed(-126, 10);
          else
            b_mantissa(23) <= '1';
          end if;
        end if;
      end if;
      
      -- Stage 3: Normalization
      if counter = "011" then
        if a_mantissa(23) = '0' then
          a_mantissa <= shift_left(a_mantissa, 1);
          a_exponent <= a_exponent - 1;
        end if;
        if b_mantissa(23) = '0' then
          b_mantissa <= shift_left(b_mantissa, 1);
          b_exponent <= b_exponent - 1;
        end if;
      end if;
      
      -- Stage 4: Multiplication
      if counter = "100" then
        z_sign <= a_sign xor b_sign;
        z_exponent <= a_exponent + b_exponent + 1;
        product <= shift_left(resize(a_mantissa * b_mantissa, 50), 2);
      end if;
      
      -- Stage 5: Extract mantissa and rounding bits
      if counter = "101" then
        z_mantissa <= product(49 downto 26);
        guard_bit <= product(25);
        round_bit <= product(24);
        if product(23 downto 0) /= x"000000" then
          sticky <= '1';
        else
          sticky <= '0';
        end if;
      end if;
      
      -- Stage 6: Rounding and adjustment
      if counter = "110" then
        if z_exponent < -126 then
          shift_amount := to_integer(-126 - z_exponent);
          z_exponent <= z_exponent + to_signed(shift_amount, 10);
          z_mantissa <= shift_right(z_mantissa, shift_amount);
          guard_bit <= z_mantissa(0);
          round_bit <= guard_bit;
          sticky <= sticky or round_bit;
        elsif z_mantissa(23) = '0' then
          z_exponent <= z_exponent - 1;
          z_mantissa <= shift_left(z_mantissa, 1);
          z_mantissa(0) <= guard_bit;
          guard_bit <= round_bit;
          round_bit <= '0';
        elsif guard_bit = '1' and (round_bit = '1' or sticky = '1' or z_mantissa(0) = '1') then
          z_mantissa <= z_mantissa + 1;
          if z_mantissa = x"FFFFFF" then
            z_exponent <= z_exponent + 1;
          end if;
        end if;
      end if;
      
      -- Stage 7: Final output
      if counter = "111" then
        z_reg(22 downto 0) <= std_logic_vector(z_mantissa(22 downto 0));
        z_reg(30 downto 23) <= std_logic_vector(resize(unsigned(z_exponent(7 downto 0)) + 127, 8));
        z_reg(31) <= z_sign;
        
        if z_exponent = -126 and z_mantissa(23) = '0' then
          z_reg(30 downto 23) <= (others => '0');
        end if;
        
        if z_exponent > 127 then
          z_reg(22 downto 0) <= (others => '0');
          z_reg(30 downto 23) <= (others => '1');
          z_reg(31) <= z_sign;
        end if;
      end if;
      
    end if;
  end process;

end architecture rtl;