-- (2) DUT implementation (traffic_light)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity traffic_light is
  port (
    rst_n        : in  std_logic;
    clk          : in  std_logic;
    pass_request : in  std_logic;
    clock        : out std_logic_vector(7 downto 0);
    red          : out std_logic;
    yellow       : out std_logic;
    green        : out std_logic
  );
end entity traffic_light;

architecture rtl of traffic_light is
  -- State encoding
  type state_t is (idle, s1_red, s2_yellow, s3_green);
  signal state : state_t;
  
  -- Internal signals
  signal cnt : unsigned(7 downto 0);
  signal p_red, p_yellow, p_green : std_logic;
  
begin

  -- State machine process
  state_machine_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      state <= idle;
      p_red <= '0';
      p_green <= '0';
      p_yellow <= '0';
    elsif rising_edge(clk) then
      case state is
        when idle =>
          p_red <= '0';
          p_green <= '0';
          p_yellow <= '0';
          state <= s1_red;
          
        when s1_red =>
          p_red <= '1';
          p_green <= '0';
          p_yellow <= '0';
          if cnt = 3 then
            state <= s3_green;
          else
            state <= s1_red;
          end if;
          
        when s2_yellow =>
          p_red <= '0';
          p_green <= '0';
          p_yellow <= '1';
          if cnt = 3 then
            state <= s1_red;
          else
            state <= s2_yellow;
          end if;
          
        when s3_green =>
          p_red <= '0';
          p_green <= '1';
          p_yellow <= '0';
          if cnt = 3 then
            state <= s2_yellow;
          else
            state <= s3_green;
          end if;
      end case;
    end if;
  end process;
  
  -- Counter process
  counter_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      cnt <= to_unsigned(10, 8);
    elsif rising_edge(clk) then
      if (pass_request = '1') and (green = '1') and (cnt > 10) then
        cnt <= to_unsigned(10, 8);
      elsif (green = '0') and (p_green = '1') then
        cnt <= to_unsigned(60, 8);
      elsif (yellow = '0') and (p_yellow = '1') then
        cnt <= to_unsigned(5, 8);
      elsif (red = '0') and (p_red = '1') then
        cnt <= to_unsigned(10, 8);
      else
        cnt <= cnt - 1;
      end if;
    end if;
  end process;
  
  -- Output assignment
  clock <= std_logic_vector(cnt);
  
  -- Output registers process
  output_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      yellow <= '0';
      red <= '0';
      green <= '0';
    elsif rising_edge(clk) then
      yellow <= p_yellow;
      red <= p_red;
      green <= p_green;
    end if;
  end process;
  
end architecture rtl;