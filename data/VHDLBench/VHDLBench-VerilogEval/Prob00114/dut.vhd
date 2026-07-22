-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: Keyboard scancode decoder

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
  port (
    code       : in  std_logic_vector(7 downto 0);
    signal_out : out std_logic_vector(3 downto 0);
    valid      : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  process(code)
  begin
    signal_out <= "0000";
    valid <= '1';
    
    case code is
      when x"45" =>
        signal_out <= "0000";
        
      when x"16" =>
        signal_out <= "0001";
        
      when x"1e" =>
        signal_out <= "0010";
        
      when x"26" =>
        signal_out <= "0011";
        
      when x"25" =>
        signal_out <= "0100";
        
      when x"2e" =>
        signal_out <= "0101";
        
      when x"36" =>
        signal_out <= "0110";
        
      when x"3d" =>
        signal_out <= "0111";
        
      when x"3e" =>
        signal_out <= "1000";
        
      when x"46" =>
        signal_out <= "1001";
        
      when others =>
        valid <= '0';
    end case;
  end process;

end architecture rtl;