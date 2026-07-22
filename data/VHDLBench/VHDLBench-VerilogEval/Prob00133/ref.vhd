-- (3) Reference implementation (RefModule)
-- Reference Module: FSM for detecting exactly 2 ones in 3 clock cycles
-- State encoding: A=0, B=1, C=2, S10=3, S11=4, S20=5, S21=6, S22=7
-- States track pattern of w over 3 cycles

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    s     : in  std_logic;
    w     : in  std_logic;
    z     : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding (matches Verilog parameters)
  constant A   : unsigned(2 downto 0) := to_unsigned(0, 3);
  constant B   : unsigned(2 downto 0) := to_unsigned(1, 3);
  constant C   : unsigned(2 downto 0) := to_unsigned(2, 3);
  constant S10 : unsigned(2 downto 0) := to_unsigned(3, 3);
  constant S11 : unsigned(2 downto 0) := to_unsigned(4, 3);
  constant S20 : unsigned(2 downto 0) := to_unsigned(5, 3);
  constant S21 : unsigned(2 downto 0) := to_unsigned(6, 3);
  constant S22 : unsigned(2 downto 0) := to_unsigned(7, 3);
  
  signal state : unsigned(2 downto 0) := A;
  signal next_state : unsigned(2 downto 0);
  
begin
  
  -- State register
  -- Matches Verilog: always @(posedge clk)
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= A;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  -- Next state logic
  -- Matches Verilog: always_comb
  process(state, s, w)
  begin
    case state is
      when A =>
        if s = '1' then
          next_state <= B;
        else
          next_state <= A;
        end if;
        
      when B =>
        if w = '1' then
          next_state <= S11;
        else
          next_state <= S10;
        end if;
        
      when C =>
        if w = '1' then
          next_state <= S11;
        else
          next_state <= S10;
        end if;
        
      when S10 =>
        if w = '1' then
          next_state <= S21;
        else
          next_state <= S20;
        end if;
        
      when S11 =>
        if w = '1' then
          next_state <= S22;
        else
          next_state <= S21;
        end if;
        
      when S20 =>
        next_state <= B;
        
      when S21 =>
        if w = '1' then
          next_state <= C;
        else
          next_state <= B;
        end if;
        
      when S22 =>
        if w = '1' then
          next_state <= B;
        else
          next_state <= C;
        end if;
        
      when others =>
        next_state <= (others => 'X');
    end case;
  end process;
  
  -- Output logic
  -- Matches Verilog: assign z = (state == C);
  z <= '1' when (state = C) else '0';

end architecture rtl;