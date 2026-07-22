-- LIFO Buffer Implementation in VHDL
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LIFObuffer is
  port (
    dataIn  : in  std_logic_vector(3 downto 0);
    RW      : in  std_logic;
    EN      : in  std_logic;
    Rst     : in  std_logic;
    Clk     : in  std_logic;
    EMPTY   : out std_logic;
    FULL    : out std_logic;
    dataOut : out std_logic_vector(3 downto 0)
  );
end entity LIFObuffer;

architecture rtl of LIFObuffer is
  type stack_mem_t is array (0 to 3) of std_logic_vector(3 downto 0);
  signal stack_mem : stack_mem_t;
  signal SP : unsigned(2 downto 0);
  
begin

  process(Clk)
    variable SP_temp : unsigned(2 downto 0);
  begin
    if rising_edge(Clk) then
      if EN = '0' then
        -- Do nothing if EN is 0
        null;
      else
        if Rst = '1' then
          -- Reset condition
          SP <= to_unsigned(4, 3);
          EMPTY <= '1';  -- SP[2] = 1 when SP = 4
          FULL <= '0';
          dataOut <= x"0";
          for i in 0 to 3 loop
            stack_mem(i) <= x"0";
          end loop;
          
        elsif Rst = '0' then
          -- Normal operation
          FULL <= '1' when SP = 0 else '0';
          EMPTY <= SP(2);
          dataOut <= (others => 'X');
          
          -- Write operation (push)
          if FULL = '0' and RW = '0' then
            SP_temp := SP - 1;
            SP <= SP_temp;
            stack_mem(to_integer(SP_temp)) <= dataIn;
            FULL <= '1' when SP_temp = 0 else '0';
            EMPTY <= SP_temp(2);
            
          -- Read operation (pop)
          elsif EMPTY = '0' and RW = '1' then
            dataOut <= stack_mem(to_integer(SP));
            stack_mem(to_integer(SP)) <= x"0";
            SP_temp := SP + 1;
            SP <= SP_temp;
            FULL <= '1' when SP_temp = 0 else '0';
            EMPTY <= SP_temp(2);
          end if;
        end if;
      end if;
    end if;
  end process;

end architecture rtl;