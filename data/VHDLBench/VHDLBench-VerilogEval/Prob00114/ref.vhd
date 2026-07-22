-- (3) Reference implementation (RefModule)
-- Reference Module: Keyboard Scancode Decoder
-- Maps 8-bit scancodes to decimal digits 0-9
-- Sets valid=1 when recognized scancode, valid=0 otherwise
-- Variable name changes: 'out' -> 'signal_out' (VHDL keyword)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    code       : in  std_logic_vector(7 downto 0);
    signal_out : out std_logic_vector(3 downto 0);
    valid      : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: always @(*) begin ... case (code) ... endcase end
  process(code)
  begin
    -- Default values (matches Verilog: out = 0; valid = 1;)
    signal_out <= "0000";
    valid <= '1';
    
    -- Case statement for scancode decoding
    case code is
      when x"45" =>  -- 8'h45: out = 0
        signal_out <= "0000";
        
      when x"16" =>  -- 8'h16: out = 1
        signal_out <= "0001";
        
      when x"1e" =>  -- 8'h1e: out = 2
        signal_out <= "0010";
        
      when x"26" =>  -- 8'h26: out = 3
        signal_out <= "0011";
        
      when x"25" =>  -- 8'h25: out = 4
        signal_out <= "0100";
        
      when x"2e" =>  -- 8'h2e: out = 5
        signal_out <= "0101";
        
      when x"36" =>  -- 8'h36: out = 6
        signal_out <= "0110";
        
      when x"3d" =>  -- 8'h3d: out = 7
        signal_out <= "0111";
        
      when x"3e" =>  -- 8'h3e: out = 8
        signal_out <= "1000";
        
      when x"46" =>  -- 8'h46: out = 9
        signal_out <= "1001";
        
      when others =>  -- default: valid = 0
        valid <= '0';
    end case;
  end process;

end architecture rtl;