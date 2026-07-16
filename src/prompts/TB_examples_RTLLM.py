"""
VHDLSuite - Few-shot Translation Example (RTLLM)
================================================

A single in-context (1-shot) demonstration used by the RTLLM construction
pipeline (src/construction/translate_rtllm.py) to guide Verilog -> VHDL-2008
testbench translation.

Two module-level string constants are defined:

  example1_input  - the user-side demonstration: an RTLLM-style problem given
                    as a `description` / `testbench` / `reference` triplet
                    (natural-language spec, Verilog self-checking testbench
                    with hardcoded expected values, and Verilog reference DUT).

  example1_output - the assistant-side demonstration: the expected VHDL-2008
                    answer, returned as a `testbench` block (VUnit tb entity
                    with embedded stimulus + verification, using the sim_done
                    convention enforced by the system prompt) and a `dut` block
                    (the translated design under test).

The translation driver injects this pair as a leading user/assistant turn
before the actual task, i.e.:

    examples = {'prompt': [example1_input], 'answer': [example1_output]}

This example demonstrates the RTLLM-specific conventions the model must follow:
self-contained testbenches (no separate reference module instantiation),
hardcoded expected-value arrays, and the summary.txt reporting format that the
simulation harness (src/simulation/run.py) parses for pass/fail classification.
"""


example1_input='''
## Input Format

```description
Please act as a professional verilog designer.

Implement a module to achieve serial input data accumulation output, input is 8bit data. The valid_in will be set to 1 before the first data comes in. Whenever the module receives 4 input data, the data_out outputs 4 received data accumulation results and sets the valid_out to be 1 (will last only 1 cycle).

Module name:  
    accu               
Input ports:
	clk: Clock input for synchronization.
	rst_n: Active-low reset signal.
	data_in[7:0]: 8-bit input data for addition.
	valid_in: Input signal indicating readiness for new data.   
Output ports:
    valid_out: Output signal indicating when 4 input data accumulation is reached.
	data_out[9:0]: 10-bit output data representing the accumulated sum.

Implementation:
When valid_in is 1, data_in is a valid input. Accumulate four valid input data_in values and calculate the output data_out by adding these four values together. 
There is no output when there are fewer than four data_in inputs in the interim. Along with the output data_out, a cycle of valid_out=1 will appear as a signal. 
The valid_out signal is set to 1 when the data_out outputs 4 received data accumulation results. Otherwise, it is set to 0.

Give me the complete code.

```

```testbench
`timescale  1ns / 1ps

module tb_valid_ready;


parameter PERIOD  = 10;
reg   clk                                  = 0 ;
reg   rst_n                                = 0 ;
reg   [7:0]  data_in                       = 0 ;
reg   valid_in                             = 0 ;

wire  valid_out                              ;
wire  [9:0]  data_out                       ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst_n  =  1;
end

accu  uut (
    .clk                     ( clk             ),
    .rst_n                   ( rst_n           ),
    .data_in                 ( data_in   [7:0] ),
    .valid_in                ( valid_in        ),

    .valid_out               ( valid_out       ),
    .data_out                ( data_out  [9:0] )
);

initial
begin
    #(PERIOD*1+0.01); 
    #(PERIOD)   data_in = 8'd1;valid_in = 1;
    #(PERIOD)   data_in = 8'd2;
    #(PERIOD)   data_in = 8'd3;
    #(PERIOD)   data_in = 8'd14;

    #(PERIOD)   data_in = 8'd5;
    #(PERIOD)   data_in = 8'd2;
    #(PERIOD)   data_in = 8'd103;
    #(PERIOD)   data_in = 8'd4;

    #(PERIOD)   data_in = 8'd5;
    #(PERIOD)   data_in = 8'd6;
    #(PERIOD)   data_in = 8'd3;
    #(PERIOD)   data_in = 8'd54;
    #(PERIOD*2);
    $finish;
end

reg [9:0] result [0:2];
initial begin
    result[0] = 9'd20;
    result[1] = 9'd114;
    result[2] = 9'd68;
end

integer i;
integer casenum = 0;
integer error = 0;

initial
begin
    for (i = 0; i < 15; i = i + 1) begin
        #((PERIOD) * 1);         
        if (valid_out) begin
            error = (data_out == result[casenum]) ? error : error + 1;
            casenum = casenum + 1;
        end        
    end
    if(error==0 && casenum==3)
	begin
		$display("===========Your Design Passed===========");
        end
	else
	begin
		$display("===========Error===========");
	end
    $finish;
end


endmodule
```

```reference
`timescale 1ns/1ns

module verified_accu(
    input               clk         ,   
    input               rst_n       ,
    input       [7:0]   data_in     ,
    input               valid_in     ,
 
    output  reg         valid_out     ,
    output  reg [9:0]   data_out
);
    
   reg [1:0] count;
   wire add_cnt;
   wire ready_add;
   wire end_cnt;
   reg [9:0]   data_out_reg;

   assign add_cnt = ready_add;
   assign end_cnt = ready_add && (count == 'd3);
   
   //count
   always @(posedge clk or negedge rst_n) begin
       if(!rst_n) begin
          count <= 0;
       end
       else if(end_cnt) begin
          count <= 0;
       end
       else if(add_cnt) begin
          count <= count + 1;
       end
   end

    //data_out_reg
   always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        data_out_reg <= 0;
      end
      else if (add_cnt && count == 0) begin
          data_out_reg <= data_in;
      end
      else if (add_cnt) begin
          data_out_reg <= data_out_reg + data_in;
      end
   end

    //data_out
   always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        data_out <= 0;
      end
      else if (add_cnt && count == 0) begin
          data_out <= data_in;
      end
      else if (add_cnt) begin
          data_out <= data_out + data_in;
      end
   end

   //ready_add
   assign ready_add = !valid_out | valid_in;

   //valid_out
   always @(posedge clk or negedge rst_n) begin
       if(!rst_n) begin
           valid_out <= 0;
       end
       else if(end_cnt) begin
           valid_out <= 1;
       end
       else begin
           valid_out <= 0;
       end
   end  
     
endmodule
```
'''

example1_output = '''
## Output Format

Return **only** the translated VHDL code, divided into **two blocks**:

```testbench
-- (1) Testbench with integrated stimulus (tb entity)
-- VUnit framework + stimulus generation + verification against expected values
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
  -- ========== Constants (from Verilog parameters) ==========
  constant PERIOD : time := 10 ns;
  
  -- ========== Signals ==========
  signal clk : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- DUT I/O signals
  signal data_in : std_logic_vector(7 downto 0) := (others => '0');
  signal valid_in : std_logic := '0';
  signal valid_out : std_logic;
  signal data_out : std_logic_vector(9 downto 0);
  
  -- ========== Expected Values (from Verilog reg result[...]) ==========
  type result_array_t is array (0 to 2) of unsigned(9 downto 0);
  constant expected_results : result_array_t := (
    0 => to_unsigned(20, 10),   -- 1+2+3+14 = 20
    1 => to_unsigned(114, 10),  -- 5+2+103+4 = 114
    2 => to_unsigned(68, 10)    -- 5+6+3+54 = 68
  );
  
  constant expected_cases : integer := 3;
  
  -- ========== Statistics ==========
  type stats_t is record
    errors             : integer;
    errortime          : time;
    errors_data_out    : integer;
    errortime_data_out : time;
    clocks             : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors             => 0,
    errortime          => 0 ps,
    errors_data_out    => 0,
    errortime_data_out => 0 ps,
    clocks             => 0
  );
  
  -- For sharing case count (use signal instead of shared variable)
  signal case_num_shared : integer := 0;
  
begin

  -- ========== Clock Generation ==========
  clk_process : process
  begin
    clk <= '0';
    wait for PERIOD / 2;
    clk <= '1';
    wait for PERIOD / 2;
  end process;
  
  -- ========== DUT Instantiation ==========
  dut1 : entity work.accu
    port map (
      clk       => clk,
      rst_n     => rst_n,
      data_in   => data_in,
      valid_in  => valid_in,
      valid_out => valid_out,
      data_out  => data_out
    );
  
  -- ========== Stimulus Generation (from Verilog initial blocks) ==========
  stimulus_process : process
  begin
    sim_done <= false;
    
    -- From: #(PERIOD*2) rst_n = 1;
    wait for PERIOD * 2;
    rst_n <= '1';
    
    -- From: #(PERIOD*1+0.01);
    wait for PERIOD * 1 + 10 ps;
    
    -- From: #(PERIOD) data_in = 8'd1; valid_in = 1;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(1, 8));
    valid_in <= '1';
    
    -- From: #(PERIOD) data_in = 8'd2;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(2, 8));
    
    -- From: #(PERIOD) data_in = 8'd3;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(3, 8));
    
    -- From: #(PERIOD) data_in = 8'd14;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(14, 8));
    
    -- From: #(PERIOD) data_in = 8'd5;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(5, 8));
    
    -- From: #(PERIOD) data_in = 8'd2;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(2, 8));
    
    -- From: #(PERIOD) data_in = 8'd103;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(103, 8));
    
    -- From: #(PERIOD) data_in = 8'd4;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(4, 8));
    
    -- From: #(PERIOD) data_in = 8'd5;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(5, 8));
    
    -- From: #(PERIOD) data_in = 8'd6;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(6, 8));
    
    -- From: #(PERIOD) data_in = 8'd3;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(3, 8));
    
    -- From: #(PERIOD) data_in = 8'd54;
    wait for PERIOD * 1;
    data_in <= std_logic_vector(to_unsigned(54, 8));
    
    -- From: #(PERIOD*2);
    wait for PERIOD * 2;
    
    -- From: $finish;
    sim_done <= true;
    wait;
  end process;
  
  -- ========== Verification Against Expected Values ==========
  verify_process : process(clk)
    variable case_num : integer := 0;
  begin
    if rising_edge(clk) then
      -- CRITICAL: Only count when simulation is active
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- From: if (valid_out) { error = (data_out == result[casenum]) ? error : error + 1; }
        if valid_out = '1' then
          -- Check data_out against expected value
          if unsigned(data_out) /= expected_results(case_num) then
            -- Increment error counters
            stats1.errors <= stats1.errors + 1;
            stats1.errors_data_out <= stats1.errors_data_out + 1;
            
            -- Record first error time
            if stats1.errors = 1 then
              stats1.errortime <= now;
            end if;
            if stats1.errors_data_out = 1 then
              stats1.errortime_data_out <= now;
            end if;
          end if;
          
          -- Increment case counter
          case_num := case_num + 1;
          case_num_shared <= case_num;  -- Update signal for report_process
        end if;
      end if;
    end if;
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
    -- Wait for timeout
    wait for 1000000 ps;
    
    -- ========== Write to summary.txt ==========
    
    -- Per-output error statistics
    if stats1.errors_data_out > 0 then
      write(l, string'("Hint: Output 'data_out' has "));
      write(l, stats1.errors_data_out);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_data_out / 1 ps);
      write(l, string'("."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'data_out' has no mismatches."));
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
    -- ===========================================
    
    file_close(f);
    
    -- ========== Console Output (mirror file) ==========
    info("========================================");
    
    if stats1.errors_data_out > 0 then
      info("Hint: Output 'data_out' has " & integer'image(stats1.errors_data_out) & 
           " mismatches. First mismatch occurred at time " & 
           integer'image(stats1.errortime_data_out / 1 ps) & ".");
    else
      info("Hint: Output 'data_out' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    
    info("========================================");
    
    -- ========== Pass/Fail (from Verilog) ==========
    if stats1.errors = 0 and case_num_shared = expected_cases then
      info("===========Your Design Passed===========");
    else
      info("===========Error===========");
      check_failed("Test failed: " & integer'image(stats1.errors) & " errors detected");
    end if;
    
    -- ========== VUnit Cleanup ==========
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;
```

```dut
-- (2) DUT implementation (TopModule)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity accu is
  port (
    clk       : in  std_logic;
    rst_n     : in  std_logic;
    data_in   : in  std_logic_vector(7 downto 0);
    valid_in  : in  std_logic;
    valid_out : out std_logic;
    data_out  : out std_logic_vector(9 downto 0)
  );
end entity accu;

architecture rtl of accu is
  signal count : unsigned(1 downto 0);
  signal data_out_reg : unsigned(9 downto 0);
  signal add_cnt : std_logic;
  signal end_cnt : std_logic;
  
begin

  -- Control signals
  add_cnt <= valid_in;
  end_cnt <= '1' when (add_cnt = '1' and count = "11") else '0';
  
  -- Counter process
  count_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      count <= (others => '0');
    elsif rising_edge(clk) then
      if end_cnt = '1' then
        count <= (others => '0');
      elsif add_cnt = '1' then
        count <= count + 1;
      end if;
    end if;
  end process;
  
  -- Accumulator process
  accumulator_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      data_out_reg <= (others => '0');
    elsif rising_edge(clk) then
      if add_cnt = '1' then
        if count = "00" then
          data_out_reg <= resize(unsigned(data_in), 10);
        else
          data_out_reg <= data_out_reg + resize(unsigned(data_in), 10);
        end if;
      end if;
    end if;
  end process;
  
  -- Output assignment
  data_out <= std_logic_vector(data_out_reg);
  
  -- Valid output process
  valid_out_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      valid_out <= '0';
    elsif rising_edge(clk) then
      if end_cnt = '1' then
        valid_out <= '1';
      else
        valid_out <= '0';
      end if;
    end if;
  end process;
  
end architecture rtl;
```
'''