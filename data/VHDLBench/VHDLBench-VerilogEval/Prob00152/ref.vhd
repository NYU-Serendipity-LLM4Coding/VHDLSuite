-- (3) Reference implementation (RefModule)
-- Reference Module: Lemmings FSM
-- Moore state machine controlling Lemming behavior
-- States: WL, WR, FALLL, FALLR, DIGL, DIGR

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk        : in  std_logic;
    areset     : in  std_logic;
    bump_left  : in  std_logic;
    bump_right : in  std_logic;
    ground     : in  std_logic;
    dig        : in  std_logic;
    walk_left  : out std_logic;
    walk_right : out std_logic;
    aaah       : out std_logic;
    digging    : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding (matches Verilog parameters)
  type state_t is (WL, WR, FALLL, FALLR, DIGL, DIGR);
  signal state : state_t;
  signal next_state : state_t;
  
begin
  
  -----------------------------------------------------------------------------
  -- Next state logic (combinational)
  -- Matches Verilog: always_comb begin case (state) ... endcase end
  -----------------------------------------------------------------------------
  next_state_logic : process(state, ground, dig, bump_left, bump_right)
  begin
    case state is
      when WL =>
        if ground = '0' then
          next_state <= FALLL;
        elsif dig = '1' then
          next_state <= DIGL;
        elsif bump_left = '1' then
          next_state <= WR;
        else
          next_state <= WL;
        end if;
        
      when WR =>
        if ground = '0' then
          next_state <= FALLR;
        elsif dig = '1' then
          next_state <= DIGR;
        elsif bump_right = '1' then
          next_state <= WL;
        else
          next_state <= WR;
        end if;
        
      when FALLL =>
        if ground = '1' then
          next_state <= WL;
        else
          next_state <= FALLL;
        end if;
        
      when FALLR =>
        if ground = '1' then
          next_state <= WR;
        else
          next_state <= FALLR;
        end if;
        
      when DIGL =>
        if ground = '1' then
          next_state <= DIGL;
        else
          next_state <= FALLL;
        end if;
        
      when DIGR =>
        if ground = '1' then
          next_state <= DIGR;
        else
          next_state <= FALLR;
        end if;
        
    end case;
  end process;
  
  -----------------------------------------------------------------------------
  -- State register (sequential)
  -- Matches Verilog: always @(posedge clk, posedge areset)
  -----------------------------------------------------------------------------
  state_register : process(clk, areset)
  begin
    if areset = '1' then
      state <= WL;  -- Asynchronous reset to walk left
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Output logic (combinational, Moore machine)
  -- Matches Verilog: assign statements
  -----------------------------------------------------------------------------
  walk_left  <= '1' when state = WL else '0';
  walk_right <= '1' when state = WR else '0';
  aaah       <= '1' when (state = FALLL or state = FALLR) else '0';
  digging    <= '1' when (state = DIGL or state = DIGR) else '0';

end architecture rtl;