library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_pipe_64bit is
  generic (
    DATA_WIDTH : integer := 64;
    STG_WIDTH  : integer := 16
  );
  port (
    clk    : in  std_logic;
    rst_n  : in  std_logic;
    i_en   : in  std_logic;
    adda   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    addb   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    result : out std_logic_vector(DATA_WIDTH downto 0);
    o_en   : out std_logic
  );
end entity;

architecture rtl of adder_pipe_64bit is

  signal stage1 : std_logic;
  signal stage2 : std_logic;
  signal stage3 : std_logic;

  signal a1, b1 : unsigned(STG_WIDTH-1 downto 0);
  signal a2, b2 : unsigned(STG_WIDTH-1 downto 0);
  signal a3, b3 : unsigned(STG_WIDTH-1 downto 0);
  signal a4, b4 : unsigned(STG_WIDTH-1 downto 0);

  signal a2_ff1, b2_ff1 : unsigned(STG_WIDTH-1 downto 0);
  signal a3_ff1, b3_ff1 : unsigned(STG_WIDTH-1 downto 0);
  signal a3_ff2, b3_ff2 : unsigned(STG_WIDTH-1 downto 0);
  signal a4_ff1, b4_ff1 : unsigned(STG_WIDTH-1 downto 0);
  signal a4_ff2, b4_ff2 : unsigned(STG_WIDTH-1 downto 0);
  signal a4_ff3, b4_ff3 : unsigned(STG_WIDTH-1 downto 0);

  signal c1, c2, c3, c4 : std_logic;
  signal s1, s2, s3, s4 : unsigned(STG_WIDTH-1 downto 0);

  signal s1_ff1, s1_ff2, s1_ff3 : unsigned(STG_WIDTH-1 downto 0);
  signal s2_ff1, s2_ff2 : unsigned(STG_WIDTH-1 downto 0);
  signal s3_ff1 : unsigned(STG_WIDTH-1 downto 0);

begin

  -- Split input operands into 16-bit segments
  a1 <= unsigned(adda(STG_WIDTH-1 downto 0));
  b1 <= unsigned(addb(STG_WIDTH-1 downto 0));
  a2 <= unsigned(adda(STG_WIDTH*2-1 downto 16));
  b2 <= unsigned(addb(STG_WIDTH*2-1 downto 16));
  a3 <= unsigned(adda(STG_WIDTH*3-1 downto 32));
  b3 <= unsigned(addb(STG_WIDTH*3-1 downto 32));
  a4 <= unsigned(adda(STG_WIDTH*4-1 downto 48));
  b4 <= unsigned(addb(STG_WIDTH*4-1 downto 48));

  -- Pipeline stage control
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      stage1 <= '0';
      stage2 <= '0';
      stage3 <= '0';
      o_en <= '0';
    elsif rising_edge(clk) then
      stage1 <= i_en;
      stage2 <= stage1;
      stage3 <= stage2;
      o_en <= stage3;
    end if;
  end process;

  -- Pipeline registers for operands
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      a2_ff1 <= (others => '0');
      b2_ff1 <= (others => '0');
      a3_ff1 <= (others => '0');
      b3_ff1 <= (others => '0');
      a3_ff2 <= (others => '0');
      b3_ff2 <= (others => '0');
      a4_ff1 <= (others => '0');
      b4_ff1 <= (others => '0');
      a4_ff2 <= (others => '0');
      b4_ff2 <= (others => '0');
      a4_ff3 <= (others => '0');
      b4_ff3 <= (others => '0');
    elsif rising_edge(clk) then
      a2_ff1 <= a2;
      b2_ff1 <= b2;
      a3_ff1 <= a3;
      b3_ff1 <= b3;
      a3_ff2 <= a3_ff1;
      b3_ff2 <= b3_ff1;
      a4_ff1 <= a4;
      b4_ff1 <= b4;
      a4_ff2 <= a4_ff1;
      b4_ff2 <= b4_ff1;
      a4_ff3 <= a4_ff2;
      b4_ff3 <= b4_ff2;
    end if;
  end process;

  -- Pipeline registers for sums
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      s1_ff1 <= (others => '0');
      s1_ff2 <= (others => '0');
      s1_ff3 <= (others => '0');
      s2_ff1 <= (others => '0');
      s2_ff2 <= (others => '0');
      s3_ff1 <= (others => '0');
    elsif rising_edge(clk) then
      s1_ff1 <= s1;
      s1_ff2 <= s1_ff1;
      s1_ff3 <= s1_ff2;
      s2_ff1 <= s2;
      s2_ff2 <= s2_ff1;
      s3_ff1 <= s3;
    end if;
  end process;

  -- Stage 1: Add a1 + b1
  process(clk, rst_n)
    variable temp : unsigned(STG_WIDTH downto 0);
  begin
    if rst_n = '0' then
      c1 <= '0';
      s1 <= (others => '0');
    elsif rising_edge(clk) then
      if i_en = '1' then
        temp := resize(a1, STG_WIDTH+1) + resize(b1, STG_WIDTH+1);
        c1 <= temp(STG_WIDTH);
        s1 <= temp(STG_WIDTH-1 downto 0);
      end if;
    end if;
  end process;

  -- Stage 2: Add a2 + b2 + c1
  process(clk, rst_n)
    variable temp : unsigned(STG_WIDTH downto 0);
    variable carry_ext : unsigned(STG_WIDTH downto 0);
  begin
    if rst_n = '0' then
      c2 <= '0';
      s2 <= (others => '0');
    elsif rising_edge(clk) then
      if stage1 = '1' then
        carry_ext := (0 => c1, others => '0');
        temp := resize(a2_ff1, STG_WIDTH+1) + resize(b2_ff1, STG_WIDTH+1) + carry_ext;
        c2 <= temp(STG_WIDTH);
        s2 <= temp(STG_WIDTH-1 downto 0);
      end if;
    end if;
  end process;

  -- Stage 3: Add a3 + b3 + c2
  process(clk, rst_n)
    variable temp : unsigned(STG_WIDTH downto 0);
    variable carry_ext : unsigned(STG_WIDTH downto 0);
  begin
    if rst_n = '0' then
      c3 <= '0';
      s3 <= (others => '0');
    elsif rising_edge(clk) then
      if stage2 = '1' then
        carry_ext := (0 => c2, others => '0');
        temp := resize(a3_ff2, STG_WIDTH+1) + resize(b3_ff2, STG_WIDTH+1) + carry_ext;
        c3 <= temp(STG_WIDTH);
        s3 <= temp(STG_WIDTH-1 downto 0);
      end if;
    end if;
  end process;

  -- Stage 4: Add a4 + b4 + c3
  process(clk, rst_n)
    variable temp : unsigned(STG_WIDTH downto 0);
    variable carry_ext : unsigned(STG_WIDTH downto 0);
  begin
    if rst_n = '0' then
      c4 <= '0';
      s4 <= (others => '0');
    elsif rising_edge(clk) then
      if stage3 = '1' then
        carry_ext := (0 => c3, others => '0');
        temp := resize(a4_ff3, STG_WIDTH+1) + resize(b4_ff3, STG_WIDTH+1) + carry_ext;
        c4 <= temp(STG_WIDTH);
        s4 <= temp(STG_WIDTH-1 downto 0);
      end if;
    end if;
  end process;

  -- Concatenate result
  result <= c4 & std_logic_vector(s4 & s3_ff1 & s2_ff2 & s1_ff3);

end architecture rtl;