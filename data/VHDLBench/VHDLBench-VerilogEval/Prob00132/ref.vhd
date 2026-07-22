-- (3) Reference implementation (RefModule)
-- Reference Module: Correct combinational logic implementation
-- Two always blocks with complete if-else statements
-- Bug fixes: Added else clauses to prevent latches

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    cpu_overheated    : in  std_logic;
    arrived           : in  std_logic;
    gas_tank_empty    : in  std_logic;
    shut_off_computer : out std_logic;
    keep_driving      : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- First always block: shut_off_computer logic
  -- Matches Verilog: always @(*) begin if (cpu_overheated) ... else ... end
  process(cpu_overheated)
  begin
    if cpu_overheated = '1' then
      shut_off_computer <= '1';
    else
      shut_off_computer <= '0';
    end if;
  end process;
  
  -- Second always block: keep_driving logic
  -- Matches Verilog: always @(*) begin if (~arrived) ... else ... end
  process(arrived, gas_tank_empty)
  begin
    if arrived = '0' then
      keep_driving <= not gas_tank_empty;
    else
      keep_driving <= '0';
    end if;
  end process;

end architecture rtl;