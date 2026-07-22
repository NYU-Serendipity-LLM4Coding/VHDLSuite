-- (3) Reference implementation (RefModule)
-- Reference Module: Lemmings FSM
-- Complex state machine with walking, falling, digging, and splatting
-- States: WL, WR, FALLL, FALLR, DIGL, DIGR, DEAD

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
  
  -- State encoding (matches Verilog parameter declarations)
  type state_type is (WL, WR, FALLL, FALLR, DIGL, DIGR, DEAD);
  signal state : state_type;
  signal next_state : state_type;
  
  -- Fall counter (5 bits to count up to 20+)
  signal fall_counter : unsigned(4 downto 0);
  
begin
  
  -----------------------------------------------------------------------------
  -- Next state logic (combinational)
  -- Matches Verilog: always_comb
  -----------------------------------------------------------------------------
  next_state_logic : process(state, ground, dig, bump_left, bump_right, fall_counter)
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
          if fall_counter >= 20 then
            next_state <= DEAD;
          else
            next_state <= WL;
          end if;
        else
          next_state <= FALLL;
        end if;
        
      when FALLR =>
        if ground = '1' then
          if fall_counter >= 20 then
            next_state <= DEAD;
          else
            next_state <= WR;
          end if;
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
        
      when DEAD =>
        next_state <= DEAD;
        
    end case;
  end process;
  
  -----------------------------------------------------------------------------
  -- State register
  -- Matches Verilog: always @(posedge clk, posedge areset)
  -----------------------------------------------------------------------------
  state_register : process(clk, areset)
  begin
    if areset = '1' then
      state <= WL;
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Fall counter
  -- Matches Verilog: always @(posedge clk)
  -----------------------------------------------------------------------------
  fall_counter_process : process(clk)
  begin
    if rising_edge(clk) then
      if state = FALLL or state = FALLR then
        if fall_counter < 20 then
          fall_counter <= fall_counter + 1;
        end if;
      else
        fall_counter <= (others => '0');
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Output logic (Moore machine - outputs depend only on state)
  -----------------------------------------------------------------------------
  walk_left  <= '1' when state = WL else '0';
  walk_right <= '1' when state = WR else '0';
  aaah       <= '1' when (state = FALLL or state = FALLR) else '0';
  digging    <= '1' when (state = DIGL or state = DIGR) else '0';

end architecture rtl;