-- (2) DUT implementation (TopModule)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity calendar is
    port (
        CLK   : in  std_logic;
        RST   : in  std_logic;
        Hours : out std_logic_vector(5 downto 0);
        Mins  : out std_logic_vector(5 downto 0);
        Secs  : out std_logic_vector(5 downto 0)
    );
end entity calendar;

architecture rtl of calendar is
    signal r_secs : unsigned(5 downto 0);
    signal r_mins : unsigned(5 downto 0);
    signal r_hours : unsigned(5 downto 0);
begin

    -- Seconds Logic
    process(CLK, RST)
    begin
        if RST = '1' then
            r_secs <= (others => '0');
        elsif rising_edge(CLK) then
            if r_secs = 59 then
                r_secs <= (others => '0');
            else
                r_secs <= r_secs + 1;
            end if;
        end if;
    end process;

    -- Minutes Logic
    process(CLK, RST)
    begin
        if RST = '1' then
            r_mins <= (others => '0');
        elsif rising_edge(CLK) then
            if r_mins = 59 and r_secs = 59 then
                r_mins <= (others => '0');
            elsif r_secs = 59 then
                r_mins <= r_mins + 1;
            end if;
        end if;
    end process;

    -- Hours Logic
    process(CLK, RST)
    begin
        if RST = '1' then
            r_hours <= (others => '0');
        elsif rising_edge(CLK) then
            if r_hours = 23 and r_mins = 59 and r_secs = 59 then
                r_hours <= (others => '0');
            elsif r_mins = 59 and r_secs = 59 then
                r_hours <= r_hours + 1;
            end if;
        end if;
    end process;

    -- Output Assignments
    Hours <= std_logic_vector(r_hours);
    Mins  <= std_logic_vector(r_mins);
    Secs  <= std_logic_vector(r_secs);

end architecture rtl;