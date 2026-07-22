-- (2) DUT implementation (alu entity)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
  port (
    a        : in  std_logic_vector(31 downto 0);
    b        : in  std_logic_vector(31 downto 0);
    aluc     : in  std_logic_vector(5 downto 0);
    r        : out std_logic_vector(31 downto 0);
    zero     : out std_logic;
    carry    : out std_logic;
    negative : out std_logic;
    overflow : out std_logic;
    flag     : out std_logic
  );
end entity alu;

architecture rtl of alu is
  
  -- Operation codes
  constant ADD  : std_logic_vector(5 downto 0) := "100000";
  constant ADDU : std_logic_vector(5 downto 0) := "100001";
  constant SUB  : std_logic_vector(5 downto 0) := "100010";
  constant SUBU : std_logic_vector(5 downto 0) := "100011";
  constant c_AND : std_logic_vector(5 downto 0) := "100100";
  constant c_OR  : std_logic_vector(5 downto 0) := "100101";
  constant c_XOR : std_logic_vector(5 downto 0) := "100110";
  constant c_NOR : std_logic_vector(5 downto 0) := "100111";
  constant SLT  : std_logic_vector(5 downto 0) := "101010";
  constant SLTU : std_logic_vector(5 downto 0) := "101011";
  constant OP_SLL  : std_logic_vector(5 downto 0) := "000000";
  constant OP_SRL  : std_logic_vector(5 downto 0) := "000010";
  constant OP_SRA  : std_logic_vector(5 downto 0) := "000011";
  constant SLLV : std_logic_vector(5 downto 0) := "000100";
  constant SRLV : std_logic_vector(5 downto 0) := "000110";
  constant SRAV : std_logic_vector(5 downto 0) := "000111";
  constant LUI  : std_logic_vector(5 downto 0) := "001111";
  
  signal a_signed : signed(31 downto 0);
  signal b_signed : signed(31 downto 0);
  signal res : std_logic_vector(32 downto 0);
  
begin

  a_signed <= signed(a);
  b_signed <= signed(b);
  
  -- Main ALU operation
  alu_proc : process(a, b, aluc, a_signed, b_signed)
    variable res_temp : signed(32 downto 0);
    variable res_u : unsigned(32 downto 0);
    variable shift_amount : integer;
    variable b_shifted : unsigned(31 downto 0);
    variable b_shifted_s : signed(31 downto 0);
  begin
    res_temp := (others => '0');
    res_u := (others => '0');
    
    case aluc is
      when ADD =>
        res_temp := resize(a_signed, 33) + resize(b_signed, 33);
        res <= std_logic_vector(res_temp);
        
      when ADDU =>
        res_u := resize(unsigned(a), 33) + resize(unsigned(b), 33);
        res <= std_logic_vector(res_u);
        
      when SUB =>
        res_temp := resize(a_signed, 33) - resize(b_signed, 33);
        res <= std_logic_vector(res_temp);
        
      when SUBU =>
        res_u := resize(unsigned(a), 33) - resize(unsigned(b), 33);
        res <= std_logic_vector(res_u);
        
      when c_AND =>
        res <= '0' & (a and b);
        
      when c_OR =>
        res <= '0' & (a or b);
        
      when c_XOR =>
        res <= '0' & (a xor b);
        
      when c_NOR =>
        res <= '0' & (not (a or b));
        
      when SLT =>
        if a_signed < b_signed then
          res <= (0 => '1', others => '0');
        else
          res <= (others => '0');
        end if;
        
      when SLTU =>
        if unsigned(a) < unsigned(b) then
          res <= (0 => '1', others => '0');
        else
          res <= (others => '0');
        end if;
        
      when OP_SLL =>
        shift_amount := to_integer(unsigned(a));
        if shift_amount < 32 then
          b_shifted := shift_left(unsigned(b), shift_amount);
        else
          b_shifted := (others => '0');
        end if;
        res <= '0' & std_logic_vector(b_shifted);
        
      when OP_SRL =>
        shift_amount := to_integer(unsigned(a));
        if shift_amount < 32 then
          b_shifted := shift_right(unsigned(b), shift_amount);
        else
          b_shifted := (others => '0');
        end if;
        res <= '0' & std_logic_vector(b_shifted);
        
      when OP_SRA =>
        shift_amount := to_integer(unsigned(a));
        if shift_amount < 32 then
          b_shifted_s := shift_right(signed(b), shift_amount);
        else
          if b(31) = '1' then
            b_shifted_s := (others => '1');
          else
            b_shifted_s := (others => '0');
          end if;
        end if;
        res <= '0' & std_logic_vector(b_shifted_s);
        
      when SLLV =>
        shift_amount := to_integer(unsigned(a(4 downto 0)));
        b_shifted := shift_left(unsigned(b), shift_amount);
        res <= '0' & std_logic_vector(b_shifted);
        
      when SRLV =>
        shift_amount := to_integer(unsigned(a(4 downto 0)));
        b_shifted := shift_right(unsigned(b), shift_amount);
        res <= '0' & std_logic_vector(b_shifted);
        
      when SRAV =>
        shift_amount := to_integer(unsigned(a(4 downto 0)));
        b_shifted_s := shift_right(signed(b), shift_amount);
        res <= '0' & std_logic_vector(b_shifted_s);
        
      when LUI =>
        res <= '0' & a(15 downto 0) & x"0000";
        
      when others =>
        res <= (others => 'Z');
    end case;
  end process;
  
  -- Output assignments
  r <= res(31 downto 0);
  
  -- Zero flag
  zero <= '1' when unsigned(res(31 downto 0)) = 0 else '0';
  
  -- Flag output (for SLT and SLTU)
  flag_proc : process(aluc, a_signed, b_signed, a, b)
  begin
    if aluc = SLT then
      if a_signed < b_signed then
        flag <= '1';
      else
        flag <= '0';
      end if;
    elsif aluc = SLTU then
      if unsigned(a) < unsigned(b) then
        flag <= '1';
      else
        flag <= '0';
      end if;
    else
      flag <= 'Z';
    end if;
  end process;
  
  -- Carry, negative, and overflow are not fully implemented in reference
  carry    <= 'Z';
  negative <= 'Z';
  overflow <= 'Z';
  
end architecture rtl;