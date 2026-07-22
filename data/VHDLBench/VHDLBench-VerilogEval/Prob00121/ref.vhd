-- (3) Reference implementation (RefModule)
-- Reference Module: 5-State FSM
-- State encoding: A=000, B=001, C=010, D=011, E=100
-- Output z = 1 when state is D or E

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    x     : in  std_logic;
    z     : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding (matches Verilog parameters)
  constant A : std_logic_vector(2 downto 0) := "000";
  constant B : std_logic_vector(2 downto 0) := "001";
  constant C : std_logic_vector(2 downto 0) := "010";
  constant D : std_logic_vector(2 downto 0) := "011";
  constant E : std_logic_vector(2 downto 0) := "100";
  
  signal state : std_logic_vector(2 downto 0) := A;
  signal next_state : std_logic_vector(2 downto 0);
  
begin

  -- State register
  -- Matches Verilog: always @(posedge clk)
  state_reg : process(clk)
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
  next_state_logic : process(state, x)
  begin
    case state is
      when A =>
        if x = '1' then
          next_state <= B;
        else
          next_state <= A;
        end if;
        
      when B =>
        if x = '1' then
          next_state <= E;
        else
          next_state <= B;
        end if;
        
      when C =>
        if x = '1' then
          next_state <= B;
        else
          next_state <= C;
        end if;
        
      when D =>
        if x = '1' then
          next_state <= C;
        else
          next_state <= B;
        end if;
        
      when E =>
        if x = '1' then
          next_state <= E;
        else
          next_state <= D;
        end if;
        
      when others =>
        next_state <= (others => 'X');
    end case;
  end process;
  
  -- Output logic
  -- Matches Verilog: assign z = (state == D) || (state == E);
  z <= '1' when (state = D or state = E) else '0';

end architecture rtl;