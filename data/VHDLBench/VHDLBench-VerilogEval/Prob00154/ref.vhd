-- (3) Reference implementation (RefModule)
-- Reference Module: Message Boundary FSM with Datapath
-- FSM searches for messages starting with in[3]=1, then captures 3 bytes
-- Variable name changes: 'in' -> 'signal_in' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk       : in  std_logic;
    signal_in : in  std_logic_vector(7 downto 0);
    reset     : in  std_logic;
    out_bytes : out std_logic_vector(23 downto 0);
    done      : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  
  -- State machine states (matches Verilog parameters)
  type state_type is (BYTE1, BYTE2, BYTE3, DONE_STATE);
  signal state : state_type;
  signal next_state : state_type;
  
  -- Datapath register
  signal out_bytes_r : std_logic_vector(23 downto 0);
  
  -- Extract bit 3 from input
  signal in3 : std_logic;
  
begin

  in3 <= signal_in(3);
  
  -----------------------------------------------------------------------------
  -- Next state logic (combinational)
  -- Matches Verilog: always_comb begin case(state) ... endcase end
  -----------------------------------------------------------------------------
  process(state, in3)
  begin
    case state is
      when BYTE1 =>
        if in3 = '1' then
          next_state <= BYTE2;
        else
          next_state <= BYTE1;
        end if;
        
      when BYTE2 =>
        next_state <= BYTE3;
        
      when BYTE3 =>
        next_state <= DONE_STATE;
        
      when DONE_STATE =>
        if in3 = '1' then
          next_state <= BYTE2;
        else
          next_state <= BYTE1;
        end if;
        
    end case;
  end process;
  
  -----------------------------------------------------------------------------
  -- State register (sequential)
  -- Matches Verilog: always @(posedge clk) begin if (reset) ... end
  -----------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= BYTE1;
      else
        state <= next_state;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Done output
  -- Matches Verilog: assign done = (state==DONE);
  -----------------------------------------------------------------------------
  done <= '1' when (state = DONE_STATE) else '0';
  
  -----------------------------------------------------------------------------
  -- Datapath: shift register for capturing bytes
  -- Matches Verilog: always @(posedge clk) out_bytes_r <= {out_bytes_r[15:0], in};
  -----------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      out_bytes_r <= out_bytes_r(15 downto 0) & signal_in;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Output assignment (don't-care when not done)
  -- Matches Verilog: assign out_bytes = done ? out_bytes_r : 'x;
  -----------------------------------------------------------------------------
  out_bytes <= out_bytes_r when (state = DONE_STATE) else (others => '-');

end architecture rtl;