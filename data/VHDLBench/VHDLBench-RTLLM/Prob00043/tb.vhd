library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use std.textio.all;
use std.env.all;

entity tb is
  generic (runner_cfg : string);
end entity;

architecture sim of tb is
  
  -- ========== Signals ==========
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal a : std_logic_vector(31 downto 0) := (others => '0');
  signal b : std_logic_vector(31 downto 0) := (others => '0');
  signal aluc : std_logic_vector(5 downto 0) := (others => '0');
  signal r : std_logic_vector(31 downto 0);
  signal zero : std_logic;
  signal carry : std_logic;
  signal negative : std_logic;
  signal overflow : std_logic;
  signal flag : std_logic;
  
  -- ========== Constants for opcodes ==========
  constant ADD  : std_logic_vector(5 downto 0) := "100000";
  constant ADDU : std_logic_vector(5 downto 0) := "100001";
  constant SUB  : std_logic_vector(5 downto 0) := "100010";
  constant SUBU : std_logic_vector(5 downto 0) := "100011";
  constant c_AND : std_logic_vector(5 downto 0) := "100100";
  constant c_OR  : std_logic_vector(5 downto 0) := "100101";
  constant c_XOR : std_logic_vector(5 downto 0) := "100110";
  constant c_NOR : std_logic_vector(5 downto 0) := "100111";
  constant SLT  : std_logic_vector(5 downto 0) := "101010";
  constant SLTU : std_logic_vector(5 downto 0) := "101011";
  constant OP_SLL  : std_logic_vector(5 downto 0) := "000000";
  constant OP_SRL  : std_logic_vector(5 downto 0) := "000010";
  constant OP_SRA  : std_logic_vector(5 downto 0) := "000011";
  constant SLLV : std_logic_vector(5 downto 0) := "000100";
  constant SRLV : std_logic_vector(5 downto 0) := "000110";
  constant SRAV : std_logic_vector(5 downto 0) := "000111";
  constant LUI  : std_logic_vector(5 downto 0) := "001111";
  
  -- ========== Expected Values (read from file) ==========
  type result_array_t is array (0 to 31) of std_logic_vector(31 downto 0);
  signal expected_results : result_array_t := (others => (others => '0'));
  
  constant expected_cases : integer := 17;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_r           : integer;
    errortime_r        : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_r           => 0,
    errortime_r        => 0 ps,
    clocks             => 0
  );
  
  signal case_num_shared : integer := 0;
  
begin

  -- ========== DUT Instantiation ==========
  dut1 : entity work.alu
    port map (
      a        => a,
      b        => b,
      aluc     => aluc,
      r        => r,
      zero     => zero,
      carry    => carry,
      negative => negative,
      overflow => overflow,
      flag     => flag
    );
  
  -- ========== Read Expected Values from File ==========
  file_read_process : process
    file ref_file : text;
    variable l : line;
    variable file_status : file_open_status;
    variable temp_val : std_logic_vector(31 downto 0);
    variable idx : integer := 0;
    variable read_ok : boolean;
  begin
    file_open(file_status, ref_file, "reference.dat", read_mode);
    
    if file_status = open_ok then
      while not endfile(ref_file) and idx < 32 loop
        readline(ref_file, l);
        hread(l, temp_val, read_ok);
        if read_ok then
          expected_results(idx) <= temp_val;
          idx := idx + 1;
        end if;
      end loop;
      file_close(ref_file);
    else
      -- Fallback: use calculated values based on a=0x1c, b=0x21
      expected_results(0)  <= x"0000003d";  -- ADD:  28 + 33 = 61
      expected_results(1)  <= x"0000003d";  -- ADDU: 28 + 33 = 61
      expected_results(2)  <= x"fffffffb";  -- SUB:  28 - 33 = -5
      expected_results(3)  <= x"fffffffb";  -- SUBU: 28 - 33 (unsigned wrap)
      expected_results(4)  <= x"00000000";  -- AND:  0x1c & 0x21 = 0
      expected_results(5)  <= x"0000003d";  -- OR:   0x1c | 0x21 = 0x3d
      expected_results(6)  <= x"0000003d";  -- XOR:  0x1c ^ 0x21 = 0x3d
      expected_results(7)  <= x"ffffffc2";  -- NOR:  ~(0x1c | 0x21)
      expected_results(8)  <= x"00000001";  -- SLT:  28 < 33 = 1
      expected_results(9)  <= x"00000001";  -- SLTU: 28 < 33 = 1
      expected_results(10) <= x"10000000";  -- SLL:  33 << 28 (CORRECTED!)
      expected_results(11) <= x"00000000";  -- SRL:  33 >> 28 = 0
      expected_results(12) <= x"00000000";  -- SRA:  33 >>> 28 = 0
      expected_results(13) <= x"10000000";  -- SLLV: 33 << 28 (CORRECTED!)
      expected_results(14) <= x"00000000";  -- SRLV: 33 >> 28 = 0
      expected_results(15) <= x"00000000";  -- SRAV: 33 >>> 28 = 0
      expected_results(16) <= x"001c0000";  -- LUI:  {0x1c, 16'h0}
    end if;
    wait;
  end process;
  
  -- ========== Stimulus Generation ==========
  stimulus_process : process
    type opcode_array_t is array (0 to 16) of std_logic_vector(5 downto 0);
    variable opcodes : opcode_array_t;
  begin
    sim_done <= false;
    
    -- Initialize opcodes array
    opcodes(0)  := ADD;
    opcodes(1)  := ADDU;
    opcodes(2)  := SUB;
    opcodes(3)  := SUBU;
    opcodes(4)  := c_AND;
    opcodes(5)  := c_OR;
    opcodes(6)  := c_XOR;
    opcodes(7)  := c_NOR;
    opcodes(8)  := SLT;
    opcodes(9)  := SLTU;
    opcodes(10) := OP_SLL;
    opcodes(11) := OP_SRL;
    opcodes(12) := OP_SRA;
    opcodes(13) := SLLV;
    opcodes(14) := SRLV;
    opcodes(15) := SRAV;
    opcodes(16) := LUI;
    
    -- Set initial values
    a <= x"0000001c";
    b <= x"00000021";
    
    wait for 5 ns;
    
    -- Loop through all operations
    for cnt in 0 to 16 loop
      wait for 5 ns;
      aluc <= opcodes(cnt);
      wait for 5 ns;
    end loop;
    
    -- Finish simulation
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process
    variable case_num : integer := 0;
  begin
    wait for 5 ns;  -- Initial delay
    
    -- Loop through all test cases
    for cnt in 0 to 16 loop
      wait for 5 ns;  -- Wait for aluc assignment
      wait for 5 ns;  -- Wait for result to settle
      
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Check r against expected value
        if r /= expected_results(cnt) then
          stats1.errors <= stats1.errors + 1;
          stats1.errors_r <= stats1.errors_r + 1;
          
          if stats1.errors = 1 then
            stats1.errortime <= now;
          end if;
          if stats1.errors_r = 1 then
            stats1.errortime_r <= now;
          end if;
        end if;
        
        case_num := case_num + 1;
        case_num_shared <= case_num;
      end if;
    end loop;
    
    wait;
  end process;
  
  -- ========== VUnit Test Runner ==========
  test_runner : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait;
  end process;
  
  -- ========== Report Generation ==========
  report_process : process
    file f : text open write_mode is "summary.txt";
    variable l : line;
  begin
    wait until sim_done;
    wait for 20 ns;
    
    -- ========== Write to summary.txt ==========
    
    if stats1.errors_r > 0 then
      write(l, string'("Hint: Output 'r' has "));
      write(l, stats1.errors_r);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_r / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'r' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- ========== MANDATORY THREE LINES ==========
    write(l, string'("Hint: Total mismatched samples is "));
    write(l, stats1.errors);
    write(l, string'(" out of "));
    write(l, stats1.clocks);
    write(l, string'(" samples"));
    writeline(f, l);
    
    write(l, string'("Simulation finished at "));
    write(l, now / 1 ps);
    write(l, string'(" ps"));
    writeline(f, l);
    
    write(l, string'("Mismatches: "));
    write(l, stats1.errors);
    write(l, string'(" in "));
    write(l, stats1.clocks);
    write(l, string'(" samples"));
    writeline(f, l);
    
    file_close(f);
    
    -- ========== Console Output ==========
    info("========================================");
    
    if stats1.errors_r > 0 then
      info("Hint: Output 'r' has " & integer'image(stats1.errors_r) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_r / 1 ps) & ".");
    else
      info("Hint: Output 'r' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail ==========
    if stats1.errors = 0 and case_num_shared = expected_cases then
      info("===========Your Design Passed===========");
    else
      info("===========Error===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;