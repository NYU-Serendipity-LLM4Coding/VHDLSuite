-- (2) DUT implementation (TopModule)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity dual_port_RAM is
  generic (DEPTH : integer := 16; WIDTH : integer := 8);
  port (
    wclk, wenc : in std_logic;
    waddr : in std_logic_vector(integer(ceil(log2(real(DEPTH))))-1 downto 0);
    wdata : in std_logic_vector(WIDTH-1 downto 0);
    rclk, renc : in std_logic;
    raddr : in std_logic_vector(integer(ceil(log2(real(DEPTH))))-1 downto 0);
    rdata : out std_logic_vector(WIDTH-1 downto 0)
  );
end entity;

architecture rtl of dual_port_RAM is
  type ram_type is array (0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);
  signal RAM_MEM : ram_type := (others => (others => '0'));
begin
  process(wclk)
  begin
    if rising_edge(wclk) then
      if wenc = '1' then RAM_MEM(to_integer(unsigned(waddr))) <= wdata; end if;
    end if;
  end process;

  process(rclk)
  begin
    if rising_edge(rclk) then
      if renc = '1' then rdata <= RAM_MEM(to_integer(unsigned(raddr))); end if;
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity TopModule is
  generic (WIDTH : integer := 8; DEPTH : integer := 16);
  port (
    wclk, rclk, wrstn, rrstn, winc, rinc : in std_logic;
    wdata : in std_logic_vector(WIDTH-1 downto 0);
    wfull, rempty : out std_logic;
    rdata : out std_logic_vector(WIDTH-1 downto 0)
  );
end entity;

architecture rtl of TopModule is
  constant ADDR_WIDTH : integer := integer(ceil(log2(real(DEPTH))));
  
  signal waddr_bin, raddr_bin : unsigned(ADDR_WIDTH downto 0) := (others => '0');
  signal waddr_gray, raddr_gray : std_logic_vector(ADDR_WIDTH downto 0);
  signal wptr, rptr : std_logic_vector(ADDR_WIDTH downto 0) := (others => '0');
  signal wptr_buff, wptr_syn, rptr_buff, rptr_syn : std_logic_vector(ADDR_WIDTH downto 0) := (others => '0');
  
  signal wen, ren : std_logic;
  signal waddr, raddr : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal wfull_int, rempty_int : std_logic;
begin
  -- Pointers
  process(wclk, wrstn)
  begin
    if wrstn = '0' then waddr_bin <= (others => '0');
    elsif rising_edge(wclk) then
      if wfull_int = '0' and winc = '1' then waddr_bin <= waddr_bin + 1; end if;
    end if;
  end process;

  process(rclk, rrstn)
  begin
    if rrstn = '0' then raddr_bin <= (others => '0');
    elsif rising_edge(rclk) then
      if rempty_int = '0' and rinc = '1' then raddr_bin <= raddr_bin + 1; end if;
    end if;
  end process;

  waddr_gray <= std_logic_vector(waddr_bin xor ('0' & waddr_bin(ADDR_WIDTH downto 1)));
  raddr_gray <= std_logic_vector(raddr_bin xor ('0' & raddr_bin(ADDR_WIDTH downto 1)));

  process(wclk, wrstn)
  begin
    if wrstn = '0' then wptr <= (others => '0');
    elsif rising_edge(wclk) then wptr <= waddr_gray; end if;
  end process;

  process(rclk, rrstn)
  begin
    if rrstn = '0' then rptr <= (others => '0');
    elsif rising_edge(rclk) then rptr <= raddr_gray; end if;
  end process;

  -- Synchronization
  process(wclk, wrstn)
  begin
    if wrstn = '0' then rptr_buff <= (others => '0'); rptr_syn <= (others => '0');
    elsif rising_edge(wclk) then rptr_buff <= rptr; rptr_syn <= rptr_buff; end if;
  end process;

  process(rclk, rrstn)
  begin
    if rrstn = '0' then wptr_buff <= (others => '0'); wptr_syn <= (others => '0');
    elsif rising_edge(rclk) then wptr_buff <= wptr; wptr_syn <= wptr_buff; end if;
  end process;

  wfull_int <= '1' when (wptr = (not rptr_syn(ADDR_WIDTH) & not rptr_syn(ADDR_WIDTH-1) & rptr_syn(ADDR_WIDTH-2 downto 0))) else '0';
  rempty_int <= '1' when (rptr = wptr_syn) else '0';

  -- Output
  wfull  <= wfull_int;
  rempty <= rempty_int;
  wen <= winc and not wfull_int;
  ren <= rinc and not rempty_int;
  waddr <= std_logic_vector(waddr_bin(ADDR_WIDTH-1 downto 0));
  raddr <= std_logic_vector(raddr_bin(ADDR_WIDTH-1 downto 0));

  ram_inst : entity work.dual_port_RAM
    generic map (DEPTH => DEPTH, WIDTH => WIDTH)
    port map (wclk => wclk, wenc => wen, waddr => waddr, wdata => wdata, rclk => rclk, renc => ren, raddr => raddr, rdata => rdata);
end architecture;
