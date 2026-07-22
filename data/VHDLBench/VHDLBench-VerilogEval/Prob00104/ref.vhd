-- (3) Reference implementation (RefModule)
-- Reference Module: Flip-Flop with 2:1 Mux
-- When L=1, loads r_in; when L=0, loads q_in
-- Positive edge triggered by clk

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk  : in  std_logic;
    L    : in  std_logic;
    q_in : in  std_logic;
    r_in : in  std_logic;
    Q    : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  -- Matches Verilog: initial Q=0;
  signal Q_reg : std_logic := '0';
begin
  
  Q <= Q_reg;
  
  -- Matches Verilog: always @(posedge clk) Q <= L ? r_in : q_in;
  process(clk)
  begin
    if rising_edge(clk) then
      if L = '1' then
        Q_reg <= r_in;
      else
        Q_reg <= q_in;
      end if;
    end if;
  end process;

end architecture rtl;