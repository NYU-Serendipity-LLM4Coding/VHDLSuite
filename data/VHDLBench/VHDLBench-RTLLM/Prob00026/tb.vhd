library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

use std.textio.all;
use std.env.all;

entity tb is
  generic (runner_cfg : string);
end entity;

architecture sim of tb is
  -- ========== Constants ==========
  constant WIDTH : integer := 8;
  constant DEPTH : integer := 16;
  constant ADDR_WIDTH : integer := integer(ceil(log2(real(DEPTH))));
  
  -- Clock Settings (Matches Verilog #5 and #10 toggles)
  constant WCLK_PERIOD : time := 10 ns; 
  constant RCLK_PERIOD : time := 20 ns;
  constant NUM_CHECKS  : integer := 48; 
  
  -- ========== Signals ==========
  signal wclk : std_logic := '0';
  signal rclk : std_logic := '0';
  signal wrstn : std_logic := '0';
  signal rrstn : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- Control
  signal check_enable : std_logic := '0';

  -- DUT I/O
  signal winc : std_logic := '0';
  signal rinc : std_logic := '0';
  signal wdata : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  signal wfull : std_logic;
  signal rempty : std_logic;
  signal rdata : std_logic_vector(WIDTH-1 downto 0);
  
  -- ========== Reference Model Signals ==========
  signal ref_wfull  : std_logic;
  signal ref_rempty : std_logic;
  signal ref_rdata  : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  
  signal ref_waddr_bin : unsigned(ADDR_WIDTH downto 0) := (others => '0');
  signal ref_raddr_bin : unsigned(ADDR_WIDTH downto 0) := (others => '0');
  
  signal ref_wptr, ref_rptr : std_logic_vector(ADDR_WIDTH downto 0) := (others => '0');
  signal ref_wptr_buff, ref_wptr_syn : std_logic_vector(ADDR_WIDTH downto 0) := (others => '0');
  signal ref_rptr_buff, ref_rptr_syn : std_logic_vector(ADDR_WIDTH downto 0) := (others => '0');
  
  type ref_ram_t is array (0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);
  signal ref_mem : ref_ram_t := (others => (others => '0'));

  -- Statistics
  type stats_t is record
    errors    : integer;
    errortime : time;
    clocks    : integer;
  end record;
  signal stats1 : stats_t := (0, 0 ps, 0);

begin

  -- ========== Clock Generation ==========
  wclk_process : process
  begin
    if sim_done then wait; end if;
    wclk <= '0'; wait for WCLK_PERIOD/2;
    wclk <= '1'; wait for WCLK_PERIOD/2;
  end process;

  rclk_process : process
  begin
    if sim_done then wait; end if;
    rclk <= '0'; wait for RCLK_PERIOD/2;
    rclk <= '1'; wait for RCLK_PERIOD/2;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut1 : entity work.TopModule
    generic map (WIDTH => WIDTH, DEPTH => DEPTH)
    port map (wclk, rclk, wrstn, rrstn, winc, rinc, wdata, wfull, rempty, rdata);
  
  -- ========== Reference Model Logic ==========
  -- Replicates DUT logic in Testbench for self-contained verification
  
  -- Ref Write
  process(wclk, wrstn)
  begin
    if wrstn = '0' then
      ref_waddr_bin <= (others => '0');
      ref_wptr <= (others => '0');
      ref_rptr_buff <= (others => '0');
      ref_rptr_syn <= (others => '0');
    elsif rising_edge(wclk) then
      if ref_wfull = '0' and winc = '1' then
        ref_mem(to_integer(ref_waddr_bin(ADDR_WIDTH-1 downto 0))) <= wdata;
        ref_waddr_bin <= ref_waddr_bin + 1;
      end if;
      ref_wptr <= std_logic_vector(ref_waddr_bin xor ('0' & ref_waddr_bin(ADDR_WIDTH downto 1)));
      ref_rptr_buff <= ref_rptr;
      ref_rptr_syn  <= ref_rptr_buff;
    end if;
  end process;
  
  -- Ref Read
  process(rclk, rrstn)
  begin
    if rrstn = '0' then
      ref_raddr_bin <= (others => '0');
      ref_rptr <= (others => '0');
      ref_wptr_buff <= (others => '0');
      ref_wptr_syn <= (others => '0');
      ref_rdata <= (others => '0');
    elsif rising_edge(rclk) then
      if ref_rempty = '0' and rinc = '1' then
        ref_rdata <= ref_mem(to_integer(ref_raddr_bin(ADDR_WIDTH-1 downto 0)));
        ref_raddr_bin <= ref_raddr_bin + 1;
      end if;
      ref_rptr <= std_logic_vector(ref_raddr_bin xor ('0' & ref_raddr_bin(ADDR_WIDTH downto 1)));
      ref_wptr_buff <= ref_wptr;
      ref_wptr_syn  <= ref_wptr_buff;
    end if;
  end process;
  
  -- Ref Flags
  ref_wfull  <= '1' when (ref_wptr = (not ref_rptr_syn(ADDR_WIDTH) & not ref_rptr_syn(ADDR_WIDTH-1) & ref_rptr_syn(ADDR_WIDTH-2 downto 0))) else '0';
  ref_rempty <= '1' when (ref_rptr = ref_wptr_syn) else '0';

  -- ========== Stimulus Generation ==========
  stimulus_process : process
  begin
    sim_done <= false;
    check_enable <= '0';
    
    -- 1. Reset Phase
    wrstn <= '0'; rrstn <= '0';
    winc <= '0'; rinc <= '0';
    wdata <= (others => '0');
    wait for 20 ns;
    wrstn <= '1'; rrstn <= '1';
    
    -- 2. Replicate Verilog Race Condition at T=30
    -- T=20: Verilog loop starts. winc=1, wdata=1.
    winc <= '1';
    wdata <= x"01"; 
    wait for 10 ns; 
    
    -- T=30: Verilog init block triggers. winc=1, wdata=AA.
    winc <= '1';
    wdata <= x"AA"; 
    wait for 10 ns;
    
    -- T=40: init block sets winc=0.
    winc <= '0';
    wait for 10 ns; -- Complete the 20ns cycle for loop
    
    -- 3. Fill FIFO
    wdata <= x"AB"; -- wdata increments from AA
    
    for i in 0 to 15 loop
       if wfull = '0' then
         winc <= '1';
         wait for 10 ns;
         winc <= '0';
         wdata <= std_logic_vector(unsigned(wdata) + 1);
         wait for 20 ns; -- Match Verilog #20
       else
         wait for 30 ns;
       end if;
    end loop;
    
    -- 4. Verification
    -- Wait time to align with roughly 550ns
    wait for 20 ns;
    
    -- Enable Read
    -- CRITICAL: Assert rinc on falling edge to ensure stable setup for posedge rclk
    wait until falling_edge(rclk);
    rinc <= '1';
    
    -- Allow one full rclk cycle for data to emerge from RAM
    wait until rising_edge(rclk); -- Latches Enable
    wait until rising_edge(rclk); -- Data Valid at Output
    
    -- Start Checking
    wait until rising_edge(wclk);
    check_enable <= '1';
    for i in 1 to NUM_CHECKS loop
      wait until rising_edge(wclk);
    end loop;
    check_enable <= '0';
    
    wait for 50 ns;
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification ==========
  verify_process : process(wclk)
  begin
    if rising_edge(wclk) then
      if not sim_done and check_enable = '1' then
        stats1.clocks <= stats1.clocks + 1;
        -- Compare output
        if (wfull /= ref_wfull) or 
           (rempty /= ref_rempty) or 
           (rdata /= ref_rdata) then
           
             stats1.errors <= stats1.errors + 1;
             if stats1.errors = 0 then
               stats1.errortime <= now;
             end if;
        end if;
      end if;
    end if;
  end process;
  
  -- ========== Report Generation ==========
  report_process : process
    file f : text;
    variable l : line;
    variable file_status : file_open_status;
  begin
    wait until sim_done;
    wait for WCLK_PERIOD * 2;
    
    file_open(file_status, f, "summary.txt", write_mode);
    
    write(l, string'("Hint: Output 'data_out' has "));
    if stats1.errors > 0 then
       write(l, stats1.errors);
       write(l, string'(" mismatches. First mismatch occurred at time "));
       write(l, stats1.errortime / 1 ps);
       write(l, string'("."));
    else
       write(l, string'("no mismatches."));
    end if;
    writeline(f, l);

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
    
    if stats1.errors = 0 then
      info("===========Your Design Passed===========");
    else
      info("===========Error===========");
      check_failed("Test failed with " & integer'image(stats1.errors) & " errors.");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;
  
  test_runner : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait;
  end process;

end architecture sim;

