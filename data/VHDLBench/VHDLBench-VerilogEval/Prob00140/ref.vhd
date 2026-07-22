-- (3) Reference implementation (RefModule)
-- Reference Module: HDLC Framing FSM
-- Moore FSM to detect:
--   - 0111110: discard bit (disc)
--   - 01111110: frame flag (flag)
--   - 01111111+: error (err)
-- Variable name changes: 'in' -> 'signal_in' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk       : in  std_logic;
    reset     : in  std_logic;
    signal_in : in  std_logic;
    disc      : out std_logic;
    flag      : out std_logic;
    err       : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding (matches Verilog parameter)
  type state_t is (S0, S1, S2, S3, S4, S5, S6, SERR, SDISC, SFLAG);
  signal state : state_t := S0;
  
begin
  
  -- Output logic (Moore FSM - outputs depend only on state)
  -- Matches Verilog: assign disc = state == SDISC;
  disc <= '1' when state = SDISC else '0';
  flag <= '1' when state = SFLAG else '0';
  err  <= '1' when state = SERR  else '0';
  
  -- State transition logic
  -- Matches Verilog: always @(posedge clk) with synchronous reset
  process(clk)
  begin
    if rising_edge(clk) then
      -- Synchronous reset (active high)
      -- Matches Verilog: if (reset) state <= S0;
      if reset = '1' then
        state <= S0;
      else
        -- State transitions
        -- Matches Verilog case statement
        case state is
          when S0 =>
            if signal_in = '1' then
              state <= S1;
            else
              state <= S0;
            end if;
            
          when S1 =>
            if signal_in = '1' then
              state <= S2;
            else
              state <= S0;
            end if;
            
          when S2 =>
            if signal_in = '1' then
              state <= S3;
            else
              state <= S0;
            end if;
            
          when S3 =>
            if signal_in = '1' then
              state <= S4;
            else
              state <= S0;
            end if;
            
          when S4 =>
            if signal_in = '1' then
              state <= S5;
            else
              state <= S0;
            end if;
            
          when S5 =>
            if signal_in = '1' then
              state <= S6;
            else
              state <= SDISC;  -- 0111110 detected
            end if;
            
          when S6 =>
            if signal_in = '1' then
              state <= SERR;  -- 01111111+ detected
            else
              state <= SFLAG;  -- 01111110 detected
            end if;
            
          when SERR =>
            if signal_in = '1' then
              state <= SERR;
            else
              state <= S0;
            end if;
            
          when SFLAG =>
            if signal_in = '1' then
              state <= S1;
            else
              state <= S0;
            end if;
            
          when SDISC =>
            if signal_in = '1' then
              state <= S1;
            else
              state <= S0;
            end if;
            
          when others =>
            state <= S0;  -- Safe fallback
        end case;
      end if;
    end if;
  end process;

end architecture rtl;