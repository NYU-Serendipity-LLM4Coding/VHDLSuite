-- (3) Reference implementation (RefModule)
-- Reference Module: 8-bit Shift Register with Multiplexer
-- Implements 8x1 memory with shift-in write and random-access read
-- S shifts into Q[0] (MSB first), ABC selects which bit to output

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk    : in  std_logic;
    enable : in  std_logic;
    S      : in  std_logic;
    A      : in  std_logic;
    B      : in  std_logic;
    C      : in  std_logic;
    Z      : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  -- 8-bit shift register (matches Verilog: reg [7:0] q;)
  signal q : std_logic_vector(7 downto 0) := (others => '0');
  
  -- Address for multiplexer (matches Verilog: {A, B, C})
  signal addr : std_logic_vector(2 downto 0);
begin

  -- Combine A, B, C into address
  addr <= A & B & C;
  
  -- Shift register
  -- Matches Verilog: always @(posedge clk) if (enable) q <= {q[6:0], S};
  process(clk)
  begin
    if rising_edge(clk) then
      if enable = '1' then
        q <= q(6 downto 0) & S;  -- Shift left, S goes into LSB (Q[0])
      end if;
    end if;
  end process;
  
  -- Multiplexer: select bit based on ABC
  -- Matches Verilog: assign Z = q[{A, B, C}];
  Z <= q(to_integer(unsigned(addr)));

end architecture rtl;