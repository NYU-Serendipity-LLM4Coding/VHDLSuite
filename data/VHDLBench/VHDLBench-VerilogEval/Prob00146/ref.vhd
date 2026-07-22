-- (3) Reference implementation (RefModule)
-- Reference Module: Serial Receiver FSM
-- Receives serial data: start bit (0), 8 data bits (LSB first), stop bit (1)
-- Outputs received byte when done=1
-- Variable name changes: 'in' -> 'signal_in'
-- State name change: 'DONE' -> 'ST_DONE' (to avoid conflict with port 'done')

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk       : in  std_logic;
    signal_in : in  std_logic;
    reset     : in  std_logic;
    out_byte  : out std_logic_vector(7 downto 0);
    done      : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State encoding (matches Verilog parameters)
  -- Changed DONE to ST_DONE to avoid conflict with port name 'done'
  type state_t is (B0, B1, B2, B3, B4, B5, B6, B7, START, STOP, ST_DONE, ERR);
  signal state : state_t;
  signal next_state : state_t;
  
  -- Shift register for received data
  signal byte_r : std_logic_vector(9 downto 0);
  
begin
  
  -----------------------------------------------------------------------------
  -- Next state logic (combinational)
  -- Matches Verilog: always_comb begin case(state) ... endcase end
  -----------------------------------------------------------------------------
  process(state, signal_in)
  begin
    case state is
      when START =>
        if signal_in = '1' then
          next_state <= START;
        else
          next_state <= B0;  -- start bit is 0
        end if;
      
      when B0 => next_state <= B1;
      when B1 => next_state <= B2;
      when B2 => next_state <= B3;
      when B3 => next_state <= B4;
      when B4 => next_state <= B5;
      when B5 => next_state <= B6;
      when B6 => next_state <= B7;
      when B7 => next_state <= STOP;
      
      when STOP =>
        if signal_in = '1' then
          next_state <= ST_DONE;  -- stop bit is 1
        else
          next_state <= ERR;
        end if;
      
      when ST_DONE =>
        if signal_in = '1' then
          next_state <= START;
        else
          next_state <= B0;
        end if;
      
      when ERR =>
        if signal_in = '1' then
          next_state <= START;
        else
          next_state <= ERR;
        end if;
      
      when others =>
        next_state <= START;
    end case;
  end process;
  
  -----------------------------------------------------------------------------
  -- State register
  -- Matches Verilog: always @(posedge clk) if (reset) state <= START; else state <= next;
  -----------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= START;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Data shift register
  -- Matches Verilog: always @(posedge clk) byte_r <= {in, byte_r[9:1]};
  -----------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      byte_r <= signal_in & byte_r(9 downto 1);
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Output logic
  -- Matches Verilog: assign done = (state==DONE);
  --                  assign out_byte = done ? byte_r[8:1] : 8'hx;
  -----------------------------------------------------------------------------
  done <= '1' when (state = ST_DONE) else '0';
  out_byte <= byte_r(8 downto 1) when (state = ST_DONE) else (others => 'X');

end architecture rtl;