-- (2) DUT implementation (TopModule)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopModule is
    port (
        clk : in std_logic;
        rst : in std_logic;
        dividend : in std_logic_vector(7 downto 0);
        divisor : in std_logic_vector(7 downto 0);
        sign : in std_logic;
        opn_valid : in std_logic;
        res_valid : out std_logic;
        res_ready : in std_logic;
        result : out std_logic_vector(15 downto 0)
    );
end entity TopModule;

architecture rtl of TopModule is
    signal SR : std_logic_vector(15 downto 0) := (others => '0');
    signal NEG_DIVISOR : std_logic_vector(8 downto 0) := (others => '0');
    
    signal sr_rem : std_logic_vector(7 downto 0);
    signal sr_quo : std_logic_vector(7 downto 0);

    signal dividend_save : std_logic_vector(7 downto 0) := (others => '0');
    signal divisor_save : std_logic_vector(7 downto 0) := (others => '0');
    
    signal dividend_abs_wire : std_logic_vector(7 downto 0);
    signal final_remainder : std_logic_vector(7 downto 0);
    signal final_quotient : std_logic_vector(7 downto 0);

    signal CO : std_logic;
    signal sub_result : std_logic_vector(8 downto 0);
    signal mux_result : std_logic_vector(8 downto 0);

    signal cnt : unsigned(3 downto 0) := (others => '0');
    signal start_cnt : std_logic := '0';
    
    signal data_go : std_logic;
    signal res_valid_reg : std_logic := '0';

begin

    sr_rem <= SR(15 downto 8);
    sr_quo <= SR(7 downto 0);

    -- Absolute Value Calculation: Use arithmetic subtraction 0-D for reliable 2's complement
    dividend_abs_wire <= std_logic_vector(to_unsigned(0, 8) - unsigned(dividend))
                         when (sign = '1' and dividend(7) = '1') 
                         else dividend;

    -- Output Sign Correction
    final_remainder <= std_logic_vector(to_unsigned(0, 8) - unsigned(sr_rem))
                       when (sign = '1' and dividend_save(7) = '1')
                       else sr_rem;

    final_quotient <= std_logic_vector(to_unsigned(0, 8) - unsigned(sr_quo))
                      when (sign = '1' and (dividend_save(7) xor divisor_save(7)) = '1')
                      else sr_quo;

    result <= final_remainder & final_quotient;

    -- Adder: {0, REM} + NEG_DIVISOR
    process(sr_rem, NEG_DIVISOR)
        variable sum_temp : unsigned(9 downto 0);
    begin
        sum_temp := resize(unsigned('0' & sr_rem), 10) + resize(unsigned(NEG_DIVISOR), 10);
        CO <= sum_temp(9);
        sub_result <= std_logic_vector(sum_temp(8 downto 0));
    end process;

    mux_result <= sub_result when CO = '1' else ('0' & sr_rem);

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                SR <= (others => '0');
                dividend_save <= (others => '0');
                divisor_save <= (others => '0');
                cnt <= (others => '0');
                start_cnt <= '0';
                NEG_DIVISOR <= (others => '0');
            elsif start_cnt = '0' and opn_valid = '1' and res_valid_reg = '0' then
                cnt <= to_unsigned(1, 4);
                start_cnt <= '1';
                
                dividend_save <= dividend;
                divisor_save <= divisor;

                SR <= "0000000" & dividend_abs_wire & '0';

                if (sign = '1' and divisor(7) = '1') then
                    NEG_DIVISOR <= '1' & divisor;
                else
                    -- Calculate -|Divisor|
                    -- divisor here is 8 bits. '0'&divisor makes it 9 bits positive. 
                    -- 0 - (9bit) performs safe 2's complement negation.
                    NEG_DIVISOR <= std_logic_vector(to_unsigned(0, 9) - resize(unsigned('0' & divisor), 9));
                end if;

            elsif start_cnt = '1' then
                if cnt(3) = '1' then
                    cnt <= (others => '0');
                    start_cnt <= '0';
                    SR <= mux_result(7 downto 0) & SR(7 downto 1) & CO;
                else
                    cnt <= cnt + 1;
                    SR <= mux_result(6 downto 0) & SR(7 downto 1) & CO & '0';
                end if;
            end if;
        end if;
    end process;

    data_go <= res_valid_reg and res_ready;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                res_valid_reg <= '0';
            elsif cnt(3) = '1' then
                res_valid_reg <= '1';
            elsif data_go = '1' then
                res_valid_reg <= '0';
            end if;
        end if;
    end process;

    res_valid <= res_valid_reg;

end architecture rtl;