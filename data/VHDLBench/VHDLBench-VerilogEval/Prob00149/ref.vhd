-- (3) Reference implementation (RefModule)
-- Reference Module: Water Level Control FSM
-- 6-state FSM with flow rate control based on water level sensors
-- States: A2, B1, B2, C1, C2, D1

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    s     : in  std_logic_vector(3 downto 1);
    fr3   : out std_logic;
    fr2   : out std_logic;
    fr1   : out std_logic;
    dfr   : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding (matches Verilog parameters)
  type state_t is (A2, B1, B2, C1, C2, D1);
  signal state, next_state : state_t;
  
  -- Flow rate vector
  signal fr : std_logic_vector(3 downto 0);
  
begin
  
  -- Output assignment
  fr3 <= fr(3);
  fr2 <= fr(2);
  fr1 <= fr(1);
  dfr <= fr(0);
  
  -- State register (matches Verilog: always @(posedge clk))
  state_reg : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= A2;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  -- Next state logic (matches Verilog: always@(*) case(state))
  next_state_logic : process(state, s)
  begin
    case state is
      when A2 =>
        if s(1) = '1' then
          next_state <= B1;
        else
          next_state <= A2;
        end if;
        
      when B1 =>
        if s(2) = '1' then
          next_state <= C1;
        elsif s(1) = '1' then
          next_state <= B1;
        else
          next_state <= A2;
        end if;
        
      when B2 =>
        if s(2) = '1' then
          next_state <= C1;
        elsif s(1) = '1' then
          next_state <= B2;
        else
          next_state <= A2;
        end if;
        
      when C1 =>
        if s(3) = '1' then
          next_state <= D1;
        elsif s(2) = '1' then
          next_state <= C1;
        else
          next_state <= B2;
        end if;
        
      when C2 =>
        if s(3) = '1' then
          next_state <= D1;
        elsif s(2) = '1' then
          next_state <= C2;
        else
          next_state <= B2;
        end if;
        
      when D1 =>
        if s(3) = '1' then
          next_state <= D1;
        else
          next_state <= C2;
        end if;
        
      when others =>
        next_state <= A2;
    end case;
  end process;
  
  -- Output logic (matches Verilog: always_comb case(state))
  output_logic : process(state)
  begin
    case state is
      when A2 =>
        fr <= "1111";
      when B1 =>
        fr <= "0110";
      when B2 =>
        fr <= "0111";
      when C1 =>
        fr <= "0010";
      when C2 =>
        fr <= "0011";
      when D1 =>
        fr <= "0000";
      when others =>
        fr <= "XXXX";
    end case;
  end process;

end architecture rtl;