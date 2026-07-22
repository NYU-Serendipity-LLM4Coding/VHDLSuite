-- (3) Reference implementation (RefModule)
-- Reference Module: GShare Branch Predictor
-- 7-bit PC, 7-bit global history, XOR-hashed indexing
-- 128-entry Pattern History Table with 2-bit saturating counters
-- Asynchronous active-high reset

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RefModule is
  port (
    clk                : in  std_logic;
    areset             : in  std_logic;
    predict_valid      : in  std_logic;
    predict_pc         : in  std_logic_vector(6 downto 0);
    predict_taken      : out std_logic;
    predict_history    : out std_logic_vector(6 downto 0);
    train_valid        : in  std_logic;
    train_taken        : in  std_logic;
    train_mispredicted : in  std_logic;
    train_history      : in  std_logic_vector(6 downto 0);
    train_pc           : in  std_logic_vector(6 downto 0)
  );
end entity RefModule;

architecture rtl of RefModule is
  
  constant n : integer := 7;
  
  -- 2-bit saturating counter states
  constant SNT : std_logic_vector(1 downto 0) := "00";  -- Strongly Not Taken
  constant LNT : std_logic_vector(1 downto 0) := "01";  -- Likely Not Taken
  constant LT  : std_logic_vector(1 downto 0) := "10";  -- Likely Taken
  constant ST  : std_logic_vector(1 downto 0) := "11";  -- Strongly Taken
  
  -- Pattern History Table (128 entries of 2-bit counters)
  type pht_array_t is array (0 to 2**n - 1) of std_logic_vector(1 downto 0);
  signal pht : pht_array_t;
  
  -- Global branch history register
  signal predict_history_r : std_logic_vector(n-1 downto 0) := (others => '0');
  
  -- Index calculations (XOR hash)
  signal predict_index : std_logic_vector(n-1 downto 0);
  signal train_index   : std_logic_vector(n-1 downto 0);
  
begin

  -- Hash function: history XOR pc
  predict_index <= predict_history_r xor predict_pc;
  train_index   <= train_history xor train_pc;
  
  -- Main sequential logic
  process(clk, areset)
  begin
    if areset = '1' then
      -- Asynchronous reset
      for i in 0 to 2**n - 1 loop
        pht(i) <= LNT;
      end loop;
      predict_history_r <= (others => '0');
      
    elsif rising_edge(clk) then
      -- Update history register on valid prediction
      if predict_valid = '1' then
        predict_history_r <= predict_history_r(n-2 downto 0) & predict_taken;
      end if;
      
      -- Train the PHT
      if train_valid = '1' then
        -- Update saturating counter
        if unsigned(pht(to_integer(unsigned(train_index)))) < 3 and train_taken = '1' then
          pht(to_integer(unsigned(train_index))) <= 
            std_logic_vector(unsigned(pht(to_integer(unsigned(train_index)))) + 1);
        elsif unsigned(pht(to_integer(unsigned(train_index)))) > 0 and train_taken = '0' then
          pht(to_integer(unsigned(train_index))) <= 
            std_logic_vector(unsigned(pht(to_integer(unsigned(train_index)))) - 1);
        end if;
        
        -- Recover history on misprediction
        if train_mispredicted = '1' then
          predict_history_r <= train_history(n-2 downto 0) & train_taken;
        end if;
      end if;
    end if;
  end process;
  
  -- Output assignments (with X propagation)
  predict_taken   <= pht(to_integer(unsigned(predict_index)))(1) when predict_valid = '1' else 'X';
  predict_history <= predict_history_r when predict_valid = '1' else (others => 'X');

end architecture rtl;