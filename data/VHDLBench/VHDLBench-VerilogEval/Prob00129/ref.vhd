-- (3) Reference implementation (RefModule)
-- Reference Module: Mealy FSM "101" Sequence Detector
-- States: S=0 (idle), S1=1 (saw '1'), S10=2 (saw '10')
-- Asynchronous active-low reset (aresetn)
-- Output z=1 when in S10 state and x=1 (completing "101")

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk     : in  std_logic;
    aresetn : in  std_logic;
    x       : in  std_logic;
    z       : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding (matches Verilog parameters)
  constant S   : unsigned(1 downto 0) := "00";  -- 0
  constant S1  : unsigned(1 downto 0) := "01";  -- 1
  constant S10 : unsigned(1 downto 0) := "10";  -- 2
  
  signal state : unsigned(1 downto 0) := S;
  signal next_state : unsigned(1 downto 0);
  
begin

  -----------------------------------------------------------------------------
  -- State register with asynchronous reset
  -- Matches Verilog: always@(posedge clk, negedge aresetn)
  -----------------------------------------------------------------------------
  state_reg : process(clk, aresetn)
  begin
    if aresetn = '0' then
      state <= S;
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Next state logic (combinational)
  -- Matches Verilog: always_comb begin case(state) ... endcase end
  -----------------------------------------------------------------------------
  next_state_logic : process(state, x)
  begin
    case state is
      when "00" =>  -- S
        if x = '1' then
          next_state <= S1;
        else
          next_state <= S;
        end if;
        
      when "01" =>  -- S1
        if x = '1' then
          next_state <= S1;
        else
          next_state <= S10;
        end if;
        
      when "10" =>  -- S10
        if x = '1' then
          next_state <= S1;
        else
          next_state <= S;
        end if;
        
      when others =>
        next_state <= "XX";  -- Don't care
    end case;
  end process;
  
  -----------------------------------------------------------------------------
  -- Output logic (Mealy - depends on state and input)
  -- Matches Verilog: always_comb begin case(state) ... endcase end
  -----------------------------------------------------------------------------
  output_logic : process(state, x)
  begin
    case state is
      when "00" =>  -- S
        z <= '0';
        
      when "01" =>  -- S1
        z <= '0';
        
      when "10" =>  -- S10
        z <= x;  -- Output 1 only when x=1 (completing "101")
        
      when others =>
        z <= 'X';
    end case;
  end process;

end architecture rtl;