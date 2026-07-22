-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement the same 6-state FSM

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    w     : in  std_logic;
    z     : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  
  -- State encoding
  constant A : unsigned(2 downto 0) := to_unsigned(0, 3);
  constant B : unsigned(2 downto 0) := to_unsigned(1, 3);
  constant C : unsigned(2 downto 0) := to_unsigned(2, 3);
  constant D : unsigned(2 downto 0) := to_unsigned(3, 3);
  constant E : unsigned(2 downto 0) := to_unsigned(4, 3);
  constant F : unsigned(2 downto 0) := to_unsigned(5, 3);
  
  signal state : unsigned(2 downto 0) := A;
  signal next_state : unsigned(2 downto 0);
  
begin

  -- State register with synchronous reset
  state_register : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= A;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  -- Next state combinational logic
  next_state_logic : process(state, w)
  begin
    case state is
      when "000" =>  -- A
        if w = '1' then
          next_state <= A;
        else
          next_state <= B;
        end if;
        
      when "001" =>  -- B
        if w = '1' then
          next_state <= D;
        else
          next_state <= C;
        end if;
        
      when "010" =>  -- C
        if w = '1' then
          next_state <= D;
        else
          next_state <= E;
        end if;
        
      when "011" =>  -- D
        if w = '1' then
          next_state <= A;
        else
          next_state <= F;
        end if;
        
      when "100" =>  -- E
        if w = '1' then
          next_state <= D;
        else
          next_state <= E;
        end if;
        
      when "101" =>  -- F
        if w = '1' then
          next_state <= D;
        else
          next_state <= C;
        end if;
        
      when others =>
        next_state <= (others => 'X');
    end case;
  end process;
  
  -- Output assignment: z is high for states E and F
  z <= '1' when (state = E or state = F) else '0';

end architecture rtl;