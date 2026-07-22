-- (2) DUT implementation (synchronizer)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity synchronizer is
  port (
    clk_a   : in  std_logic;
    clk_b   : in  std_logic;
    arstn   : in  std_logic;
    brstn   : in  std_logic;
    data_in : in  std_logic_vector(3 downto 0);
    data_en : in  std_logic;
    dataout : out std_logic_vector(3 downto 0)
  );
end entity synchronizer;

architecture rtl of synchronizer is
  signal data_reg     : std_logic_vector(3 downto 0);
  signal en_data_reg  : std_logic;
  signal en_clap_one  : std_logic;
  signal en_clap_two  : std_logic;
  signal dataout_reg  : std_logic_vector(3 downto 0);
  
begin

  -- Data register (clock domain A)
  data_reg_proc : process(clk_a, arstn)
  begin
    if arstn = '0' then
      data_reg <= (others => '0');
    elsif rising_edge(clk_a) then
      data_reg <= data_in;
    end if;
  end process;
  
  -- Enable data register (clock domain A)
  en_data_reg_proc : process(clk_a, arstn)
  begin
    if arstn = '0' then
      en_data_reg <= '0';
    elsif rising_edge(clk_a) then
      en_data_reg <= data_en;
    end if;
  end process;
  
  -- First synchronizer stage (clock domain B)
  en_clap_one_proc : process(clk_b, brstn)
  begin
    if brstn = '0' then
      en_clap_one <= '0';
    elsif rising_edge(clk_b) then
      en_clap_one <= en_data_reg;
    end if;
  end process;
  
  -- Second synchronizer stage (clock domain B)
  en_clap_two_proc : process(clk_b, brstn)
  begin
    if brstn = '0' then
      en_clap_two <= '0';
    elsif rising_edge(clk_b) then
      en_clap_two <= en_clap_one;
    end if;
  end process;
  
  -- Output register with MUX (clock domain B)
  dataout_proc : process(clk_b, brstn)
  begin
    if brstn = '0' then
      dataout_reg <= (others => '0');
    elsif rising_edge(clk_b) then
      if en_clap_two = '1' then
        dataout_reg <= data_reg;
      else
        dataout_reg <= dataout_reg;
      end if;
    end if;
  end process;
  
  -- Output assignment
  dataout <= dataout_reg;
  
end architecture rtl;