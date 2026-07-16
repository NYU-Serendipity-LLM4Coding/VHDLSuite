
#not gate
example1_input = '''
## Input Format

```reference
module RefModule (
  input in,
  output out
);

  assign out = ~in;

endmodule
```

```description
Create a module that implements a NOT gate.

module TopModule (
  input in,
  output out
);
```

```testbench
`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
	input clk,
	output reg in,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable
);


// Add two ports to module stimulus_gen:
//    output [511:0] wavedrom_title
//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	



	initial begin
		in <= 1'b0;
		wavedrom_start("Inversion");
		repeat(20) @(posedge clk)
			in <= $random;		
		wavedrom_stop();
		
		repeat(200) @(posedge clk, negedge clk)
			in <= $random;
			
		#1 $finish;
	end
	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_out;
		int errortime_out;

		int clocks;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic in;
	logic out_ref;
	logic out_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,in,out_ref,out_dut );
	end


	wire tb_match;		// Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.in );
	RefModule good1 (
		.in,
		.out(out_ref) );
		
	TopModule top_module1 (
		.in,
		.out(out_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask	

	
	final begin
		if (stats1.errors_out) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out", stats1.errors_out, stats1.errortime_out);
		else $display("Hint: Output '%s' has no mismatches.", "out");

		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
	// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
	// the sensitivity list of the @(strobe) process, which isn't implemented.
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin if (stats1.errors_out == 0) stats1.errortime_out = $time;
			stats1.errors_out = stats1.errors_out+1'b1; end

	end


   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

endmodule
```
'''

example1_output='''

## Output Format

Return **only** the translated VHDL code, divided into **four blocks in this exact order**:

```stimulus
-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator Entity
-- Generates input signals for DUT testing
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    signal_in      : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean  -- Signal when stimulus is complete
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 999;
    variable seed2    : positive := 337;
    variable rand_val : real;
    
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
    -- Wavedrom tasks (simplified, not functional in VHDL)
    procedure wavedrom_start(title : string) is
    begin
      wavedrom_enable <= '1';
      -- Note: String assignment in VHDL is complex, simplified here
    end procedure;
    
    procedure wavedrom_stop is
    begin
      wait for 1 ps;
      wavedrom_enable <= '0';
    end procedure;
    
  begin
    -- Initialize
    signal_in <= '0';
    wavedrom_enable <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Wavedrom section: "Inversion"
    wavedrom_start("Inversion");
    
    -- repeat(20) @(posedge clk)
    for i in 1 to 20 loop
      wait until rising_edge(clk);
      random_bit(signal_in);
    end loop;
    
    wavedrom_stop;
    
    -- Main test: repeat(200) @(posedge clk, negedge clk)
    for i in 1 to 200 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_bit(signal_in);
    end loop;
    
    -- Wait #1 (Verilog) before finish
    wait for 1 ps;
    
    -- Signal completion (replaces Verilog $finish)
    sim_done <= true;
    
    -- Keep process alive
    wait;
  end process;

end architecture behavioral;
```

```testbench
-- (2) Testbench (tb entity)
-- Main Testbench
-- Instantiates stimulus_gen, RefModule, and TopModule
-- Performs verification and generates summary.txt
-- Corresponds to Verilog module: tb

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use std.textio.all;
use std.env.all;

entity tb is
  generic (runner_cfg : string);
end entity tb;

architecture sim of tb is
  
  -- Clock
  signal clk : std_logic := '0';
  constant clk_period : time := 10 ps;  -- Matches `timescale 1 ps/1 ps
  
  -- DUT signals
  signal signal_in  : std_logic := '0';
  signal signal_out : std_logic;
  
  -- Reference signals  
  signal out_ref : std_logic;
  
  -- Stimulus control signals
  signal wavedrom_title  : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal sim_done        : boolean := false;
  
  -- Statistics type (matches Verilog struct stats)
  type stats_t is record
    errors         : integer;
    errortime      : time;
    errors_out     : integer;
    errortime_out  : time;
    clocks         : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors        => 0,
    errortime     => 0 ps,
    errors_out    => 0,
    errortime_out => 0 ps,
    clocks        => 0
  );
  
  -- Verification
  signal tb_match    : boolean;
  signal tb_mismatch : boolean;
  
begin

  -----------------------------------------------------------------------------
  -- Clock generation (runs forever, VUnit will stop it)
  -----------------------------------------------------------------------------
  clk_process : process
  begin
    clk <= '0';
    wait for clk_period / 2;
    clk <= '1';
    wait for clk_period / 2;
  end process;
  
  -----------------------------------------------------------------------------
  -- Stimulus generator instantiation (replaces Verilog stimulus_gen module)
  -----------------------------------------------------------------------------
  stim1 : entity work.stimulus_gen
    port map (
      clk             => clk,
      signal_in       => signal_in,
      wavedrom_title  => wavedrom_title,
      wavedrom_enable => wavedrom_enable,
      sim_done        => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation (good1 in Verilog)
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      signal_in  => signal_in,
      signal_out => out_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation (top_module1 in Verilog)
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      signal_in  => signal_in,
      signal_out => signal_out
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic (combinational)
  -- Matches Verilog: assign tb_match = (...)
  -----------------------------------------------------------------------------
  tb_match    <= (out_ref = signal_out);
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
  -- Matches Verilog: always @(posedge clk, negedge clk)
  -----------------------------------------------------------------------------
  verify_process : process(clk)
  begin
    if rising_edge(clk) or falling_edge(clk) then
      -- Only count when simulation not done (prevents extra mismatches)
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Overall match check
        if not tb_match then
          if stats1.errors = 0 then
            stats1.errortime <= now;
          end if;
          stats1.errors <= stats1.errors + 1;
        end if;
        
        -- Specific output check
        -- Verilog: if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
        if out_ref /= signal_out then
          if stats1.errors_out = 0 then
            stats1.errortime_out <= now;
          end if;
          stats1.errors_out <= stats1.errors_out + 1;
        end if;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- VUnit runner process
  -----------------------------------------------------------------------------
  test_runner : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait;  -- Wait for report process to cleanup
  end process;
  
  -----------------------------------------------------------------------------
  -- Report process
  -- Matches Verilog: final begin ... end
  -- Waits for timeout then generates summary
  -----------------------------------------------------------------------------
  report_process : process
    file f : text open write_mode is "summary.txt";
    variable l : line;
  begin
    -- Wait for timeout (matches Verilog: initial begin #1000000 $display("TIMEOUT"); end)
    wait for 1000000 ps;
    
    -- Generate summary.txt (matches Verilog final block)
    if stats1.errors_out > 0 then
      write(l, string'("Hint: Output 'out' has "));
      write(l, stats1.errors_out);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out' has no mismatches."));
      writeline(f, l);
    end if;
    
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
    
    -- Console output (matches Verilog $display)
    info("========================================");
    if stats1.errors_out > 0 then
      info("Hint: Output 'out' has " & integer'image(stats1.errors_out) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_out / 1 ps) & " ps.");
    else
      info("Hint: Output 'out' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    info("========================================");
    
    -- Pass/Fail determination
    if stats1.errors > 0 then
      check_failed("FAIL: " & integer'image(stats1.errors) & 
                   " mismatches in " & integer'image(stats1.clocks) & " samples");
    else
      info("PASS: All " & integer'image(stats1.clocks) & " samples matched!");
    end if;
    
    -- Cleanup and stop
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;
```

```reference
-- (3) Reference implementation (RefModule)
-- Reference Module: NOT gate
-- Translated from Verilog to VHDL 2008
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out' (VHDL keywords)

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    signal_in  : in  std_logic;
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  signal_out <= not signal_in;
end architecture rtl;
```

```dut
-- 对于后续的 design unit，再写一遍 library/use（很多仿真器要求）
library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    signal_in  : in  std_logic;
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  signal_out <=  not signal_in;
end architecture rtl;
```
'''

#always if
example2_input= '''
## Input Format

```reference

module RefModule (
  input a,
  input b,
  input sel_b1,
  input sel_b2,
  output out_assign,
  output reg out_always
);

  assign out_assign = (sel_b1 & sel_b2) ? b : a;
  always @(*) out_always = (sel_b1 & sel_b2) ? b : a;

endmodule
```

```description

Build a 2-to-1 mux that chooses between a and b. Choose b if both sel_b1
and sel_b2 are true. Otherwise, choose a. Do the same twice, once using
assign statements and once using a procedural if statement.

module TopModule (
  input a,
  input b,
  input sel_b1,
  input sel_b2,
  output out_assign,
  output reg out_always
);
```

```testbench
`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
	input clk,
	output logic a,b,sel_b1, sel_b2,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable	
);


// Add two ports to module stimulus_gen:
//    output [511:0] wavedrom_title
//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	



	initial begin
		{a, b, sel_b1, sel_b2} <= 4'b000;
		@(negedge clk) wavedrom_start("");
			@(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b0100;
			@(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b1000;
			@(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b1101;
			@(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b0001;
			@(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b0110;
			@(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b1010;
			@(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b1111;
			@(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b0011;
			@(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b0111;
			@(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b1011;
			@(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b1111;
			@(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b0011;
		wavedrom_stop();
		repeat(100) @(posedge clk, negedge clk)
			{a,b,sel_b1,sel_b2} <= $urandom;
		$finish;
	end
	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_out_assign;
		int errortime_out_assign;
		int errors_out_always;
		int errortime_out_always;

		int clocks;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic a;
	logic b;
	logic sel_b1;
	logic sel_b2;
	logic out_assign_ref;
	logic out_assign_dut;
	logic out_always_ref;
	logic out_always_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,a,b,sel_b1,sel_b2,out_assign_ref,out_assign_dut,out_always_ref,out_always_dut );
	end


	wire tb_match;		// Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.a,
		.b,
		.sel_b1,
		.sel_b2 );
	RefModule good1 (
		.a,
		.b,
		.sel_b1,
		.sel_b2,
		.out_assign(out_assign_ref),
		.out_always(out_always_ref) );
		
	TopModule top_module1 (
		.a,
		.b,
		.sel_b1,
		.sel_b2,
		.out_assign(out_assign_dut),
		.out_always(out_always_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask	

	
	final begin
		if (stats1.errors_out_assign) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out_assign", stats1.errors_out_assign, stats1.errortime_out_assign);
		else $display("Hint: Output '%s' has no mismatches.", "out_assign");
		if (stats1.errors_out_always) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out_always", stats1.errors_out_always, stats1.errortime_out_always);
		else $display("Hint: Output '%s' has no mismatches.", "out_always");

		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { out_assign_ref, out_always_ref } === ( { out_assign_ref, out_always_ref } ^ { out_assign_dut, out_always_dut } ^ { out_assign_ref, out_always_ref } ) );
	// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
	// the sensitivity list of the @(strobe) process, which isn't implemented.
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (out_assign_ref !== ( out_assign_ref ^ out_assign_dut ^ out_assign_ref ))
		begin if (stats1.errors_out_assign == 0) stats1.errortime_out_assign = $time;
			stats1.errors_out_assign = stats1.errors_out_assign+1'b1; end
		if (out_always_ref !== ( out_always_ref ^ out_always_dut ^ out_always_ref ))
		begin if (stats1.errors_out_always == 0) stats1.errortime_out_always = $time;
			stats1.errors_out_always = stats1.errors_out_always+1'b1; end

	end

   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

endmodule


```
'''

example2_output='''

## Output Format

Return **only** the translated VHDL code, divided into **four blocks in this exact order**:

```stimulus
-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for 2-to-1 Mux Test
-- Provides predetermined test vectors followed by random tests
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk            : in  std_logic;
    a              : out std_logic;
    b              : out std_logic;
    sel_b1         : out std_logic;
    sel_b2         : out std_logic;
    wavedrom_title : out string(1 to 512);
    wavedrom_enable: out std_logic;
    sim_done       : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
  
  -- Helper signal for 4-bit concatenation
  signal inputs : std_logic_vector(3 downto 0);
  
begin

  -- Split concatenated signal to individual outputs
  -- inputs = {a, b, sel_b1, sel_b2}
  a      <= inputs(3);
  b      <= inputs(2);
  sel_b1 <= inputs(1);
  sel_b2 <= inputs(0);

  stimulus_process : process
    variable seed1    : positive := 12345;
    variable seed2    : positive := 67890;
    variable rand_val : real;
    variable rand_int : integer;
    
    -- Apply 4-bit test vector
    procedure apply_vector(vec : std_logic_vector(3 downto 0)) is
    begin
      inputs <= vec;
    end procedure;
    
    -- Random 4-bit vector generator
    procedure random_vector is
    begin
      uniform(seed1, seed2, rand_val);
      rand_int := integer(floor(rand_val * 16.0));
      inputs <= std_logic_vector(to_unsigned(rand_int, 4));
    end procedure;
    
  begin
    -- Initialize
    inputs <= "0000";
    wavedrom_enable <= '0';
    sim_done <= false;
    
    -- Initial delay
    wait for 10 ps;
    
    -- Matches Verilog: @(negedge clk) wavedrom_start("");
    wait until falling_edge(clk);
    wavedrom_enable <= '1';
    
    -- Predetermined test vectors (matches Verilog sequence)
    -- Vector format: {a, b, sel_b1, sel_b2}
    
    wait until rising_edge(clk);  -- First edge (posedge)
    apply_vector("0100");  -- 4'b0100
    
    wait until falling_edge(clk);  -- Second edge (negedge)
    apply_vector("1000");  -- 4'b1000
    
    wait until rising_edge(clk);
    apply_vector("1101");  -- 4'b1101
    
    wait until falling_edge(clk);
    apply_vector("0001");  -- 4'b0001
    
    wait until rising_edge(clk);
    apply_vector("0110");  -- 4'b0110
    
    wait until falling_edge(clk);
    apply_vector("1010");  -- 4'b1010
    
    wait until rising_edge(clk);
    apply_vector("1111");  -- 4'b1111
    
    wait until falling_edge(clk);
    apply_vector("0011");  -- 4'b0011
    
    wait until rising_edge(clk);
    apply_vector("0111");  -- 4'b0111
    
    wait until falling_edge(clk);
    apply_vector("1011");  -- 4'b1011
    
    wait until rising_edge(clk);
    apply_vector("1111");  -- 4'b1111
    
    wait until falling_edge(clk);
    apply_vector("0011");  -- 4'b0011
    
    -- Wavedrom stop
    wait for 1 ps;
    wavedrom_enable <= '0';
    
    -- Random test: repeat(100) @(posedge clk, negedge clk)
    for i in 1 to 100 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_vector;
    end loop;
    
    -- Matches Verilog: $finish;
    sim_done <= true;
    wait;
  end process;

end architecture behavioral;
```

```testbench
-- (2) Testbench (tb entity)
-- Main Testbench for 2-to-1 Mux
-- Verifies both out_assign and out_always outputs
-- Corresponds to Verilog module: tb

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use std.textio.all;
use std.env.all;

entity tb is
  generic (runner_cfg : string);
end entity tb;

architecture sim of tb is
  
  -- Clock
  signal clk : std_logic := '0';
  constant clk_period : time := 10 ps;
  
  -- DUT signals
  signal a              : std_logic := '0';
  signal b              : std_logic := '0';
  signal sel_b1         : std_logic := '0';
  signal sel_b2         : std_logic := '0';
  signal out_assign_ref : std_logic;
  signal out_assign_dut : std_logic;
  signal out_always_ref : std_logic;
  signal out_always_dut : std_logic;
  
  -- Stimulus control
  signal wavedrom_title  : string(1 to 512);
  signal wavedrom_enable : std_logic;
  signal sim_done        : boolean := false;
  
  -- Statistics type (extended for two outputs)
  type stats_t is record
    errors                : integer;
    errortime             : time;
    errors_out_assign     : integer;
    errortime_out_assign  : time;
    errors_out_always     : integer;
    errortime_out_always  : time;
    clocks                : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors               => 0,
    errortime            => 0 ps,
    errors_out_assign    => 0,
    errortime_out_assign => 0 ps,
    errors_out_always    => 0,
    errortime_out_always => 0 ps,
    clocks               => 0
  );
  
  -- Verification
  signal tb_match    : boolean;
  signal tb_mismatch : boolean;
  
begin

  -----------------------------------------------------------------------------
  -- Clock generation
  -----------------------------------------------------------------------------
  clk_process : process
  begin
    clk <= '0';
    wait for clk_period / 2;
    clk <= '1';
    wait for clk_period / 2;
  end process;
  
  -----------------------------------------------------------------------------
  -- Stimulus generator instantiation
  -----------------------------------------------------------------------------
  stim1 : entity work.stimulus_gen
    port map (
      clk             => clk,
      a               => a,
      b               => b,
      sel_b1          => sel_b1,
      sel_b2          => sel_b2,
      wavedrom_title  => wavedrom_title,
      wavedrom_enable => wavedrom_enable,
      sim_done        => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      a          => a,
      b          => b,
      sel_b1     => sel_b1,
      sel_b2     => sel_b2,
      out_assign => out_assign_ref,
      out_always => out_always_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      a          => a,
      b          => b,
      sel_b1     => sel_b1,
      sel_b2     => sel_b2,
      out_assign => out_assign_dut,
      out_always => out_always_dut
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -- Matches Verilog: assign tb_match = ({ out_assign_ref, out_always_ref } === ...)
  -----------------------------------------------------------------------------
  tb_match <= (out_assign_ref = out_assign_dut) and 
              (out_always_ref = out_always_dut);
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
  -- Matches Verilog: always @(posedge clk, negedge clk)
  -----------------------------------------------------------------------------
  verify_process : process(clk)
  begin
    if rising_edge(clk) or falling_edge(clk) then
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Check overall match
        if not tb_match then
          if stats1.errors = 0 then
            stats1.errortime <= now;
          end if;
          stats1.errors <= stats1.errors + 1;
        end if;
        
        -- Check out_assign
        if out_assign_ref /= out_assign_dut then
          if stats1.errors_out_assign = 0 then
            stats1.errortime_out_assign <= now;
          end if;
          stats1.errors_out_assign <= stats1.errors_out_assign + 1;
        end if;
        
        -- Check out_always
        if out_always_ref /= out_always_dut then
          if stats1.errors_out_always = 0 then
            stats1.errortime_out_always <= now;
          end if;
          stats1.errors_out_always <= stats1.errors_out_always + 1;
        end if;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- VUnit runner process
  -----------------------------------------------------------------------------
  test_runner : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait;
  end process;
  
  -----------------------------------------------------------------------------
  -- Report process
  -- Matches Verilog: final begin ... end
  -----------------------------------------------------------------------------
  report_process : process
    file f : text open write_mode is "summary.txt";
    variable l : line;
  begin
    wait for 1000000 ps;
    
    -- Write summary for out_assign
    if stats1.errors_out_assign > 0 then
      write(l, string'("Hint: Output 'out_assign' has "));
      write(l, stats1.errors_out_assign);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out_assign / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out_assign' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Write summary for out_always
    if stats1.errors_out_always > 0 then
      write(l, string'("Hint: Output 'out_always' has "));
      write(l, stats1.errors_out_always);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out_always / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out_always' has no mismatches."));
      writeline(f, l);
    end if;
    
    -- Total summary
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
    
    -- Console output
    info("========================================");
    if stats1.errors_out_assign > 0 then
      info("Hint: Output 'out_assign' has " & integer'image(stats1.errors_out_assign) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_out_assign / 1 ps) & " ps.");
    else
      info("Hint: Output 'out_assign' has no mismatches.");
    end if;
    
    if stats1.errors_out_always > 0 then
      info("Hint: Output 'out_always' has " & integer'image(stats1.errors_out_always) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_out_always / 1 ps) & " ps.");
    else
      info("Hint: Output 'out_always' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    info("========================================");
    
    -- Pass/Fail
    if stats1.errors > 0 then
      check_failed("FAIL: " & integer'image(stats1.errors) & 
                   " mismatches in " & integer'image(stats1.clocks) & " samples");
    else
      info("PASS: All " & integer'image(stats1.clocks) & " samples matched!");
    end if;
    
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;
```

```reference
-- (3) Reference implementation (RefModule)
-- Reference Module: 2-to-1 Multiplexer
-- Two implementations: concurrent assignment and process
-- Select b when (sel_b1 AND sel_b2), otherwise select a

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    a          : in  std_logic;
    b          : in  std_logic;
    sel_b1     : in  std_logic;
    sel_b2     : in  std_logic;
    out_assign : out std_logic;
    out_always : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
begin
  
  -- Matches Verilog: assign out_assign = (sel_b1 & sel_b2) ? b : a;
  out_assign <= b when (sel_b1 = '1' and sel_b2 = '1') else a;
  
  -- Matches Verilog: always @(*) out_always = (sel_b1 & sel_b2) ? b : a;
  process(a, b, sel_b1, sel_b2)
  begin
    if (sel_b1 = '1' and sel_b2 = '1') then
      out_always <= b;
    else
      out_always <= a;
    end if;
  end process;

end architecture rtl;
```

```dut
-- (4) DUT implementation (TopModule)
-- User's design under test
-- Implement 2-to-1 mux with two methods

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    a          : in  std_logic;
    b          : in  std_logic;
    sel_b1     : in  std_logic;
    sel_b2     : in  std_logic;
    out_assign : out std_logic;
    out_always : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
begin
  
  -- Method 1: Concurrent assignment
  out_assign <= b when (sel_b1 = '1' and sel_b2 = '1') else a;
  
  -- Method 2: Process with if statement
  process(a, b, sel_b1, sel_b2)
  begin
    if (sel_b1 = '1' and sel_b2 = '1') then
      out_always <= b;
    else
      out_always <= a;
    end if;
  end process;

end architecture rtl;
```
'''

example3_input='''
## Input Format

```reference
module RefModule (
  input clk,
  input in,
  output logic out
);

  initial
    out = 0;

  always@(posedge clk) begin
    out <= in ^ out;
  end

endmodule
```

```description
Implement in Verilog the following circuit: A D flip-flop takes as input
the output of a two-input XOR. The flip-flop is positive edge triggered
by clk, but there is no reset. The XOR takes as input 'in' along with the
output 'out' of the flip-flop.

module TopModule (
  input clk,
  input in,
  output logic out
);
```

```testbench
`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
	input clk,
	output logic in
);

	initial begin
		repeat(100) @(posedge clk, negedge clk) begin
			in <= $random;
		end
		
		#1 $finish;
	end
	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_out;
		int errortime_out;

		int clocks;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic in;
	logic out_ref;
	logic out_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,in,out_ref,out_dut );
	end


	wire tb_match;		// Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.in );
	RefModule good1 (
		.clk,
		.in,
		.out(out_ref) );
		
	TopModule top_module1 (
		.clk,
		.in,
		.out(out_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask	

	
	final begin
		if (stats1.errors_out) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out", stats1.errors_out, stats1.errortime_out);
		else $display("Hint: Output '%s' has no mismatches.", "out");

		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
	// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
	// the sensitivity list of the @(strobe) process, which isn't implemented.
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin if (stats1.errors_out == 0) stats1.errortime_out = $time;
			stats1.errors_out = stats1.errors_out+1'b1; end

	end

   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

endmodule
```

'''

example3_output='''

## Output Format

Return **only** the translated VHDL code, divided into **four blocks in this exact order**:

```stimulus
-- (1) Stimulus generator (stimulus_gen entity)
-- Stimulus Generator for XOR Flip-Flop Test
-- Generates random input signals on clock edges
-- Corresponds to Verilog module: stimulus_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity stimulus_gen is
  port (
    clk       : in  std_logic;
    signal_in : out std_logic;
    sim_done  : out boolean
  );
end entity stimulus_gen;

architecture behavioral of stimulus_gen is
begin

  stimulus_process : process
    variable seed1    : positive := 999;
    variable seed2    : positive := 337;
    variable rand_val : real;
    
    -- Random bit generator (replaces Verilog $random)
    procedure random_bit(signal sig : out std_logic) is
    begin
      uniform(seed1, seed2, rand_val);
      sig <= '1' when rand_val > 0.5 else '0';
    end procedure;
    
  begin
    -- Initialize
    signal_in <= '0';
    sim_done <= false;
    
    wait for 10 ps;  -- Initial delay
    
    -- Matches Verilog: repeat(100) @(posedge clk, negedge clk)
    -- This means 100 clock edges (alternating rising and falling)
    for i in 1 to 100 loop
      if (i mod 2) = 1 then
        wait until rising_edge(clk);
      else
        wait until falling_edge(clk);
      end if;
      random_bit(signal_in);
    end loop;
    
    -- Matches Verilog: #1 $finish;
    wait for 1 ps;
    sim_done <= true;
    
    wait;  -- Keep process alive
  end process;

end architecture behavioral;
```

```testbench
-- (2) Testbench (tb entity)
-- Main Testbench for XOR Flip-Flop
-- Instantiates stimulus_gen, RefModule, and TopModule
-- Performs verification and generates summary.txt
-- Corresponds to Verilog module: tb

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use std.textio.all;
use std.env.all;

entity tb is
  generic (runner_cfg : string);
end entity tb;

architecture sim of tb is
  
  -- Clock
  signal clk : std_logic := '0';
  constant clk_period : time := 10 ps;  -- Matches Verilog: #5 clk = ~clk
  
  -- DUT signals (renamed to avoid VHDL keywords)
  signal signal_in  : std_logic := '0';
  signal signal_out : std_logic;
  signal out_ref    : std_logic;
  
  -- Control signal
  signal sim_done : boolean := false;
  
  -- Statistics type (matches Verilog struct stats)
  type stats_t is record
    errors         : integer;
    errortime      : time;
    errors_out     : integer;
    errortime_out  : time;
    clocks         : integer;
  end record;
  
  signal stats1 : stats_t := (
    errors        => 0,
    errortime     => 0 ps,
    errors_out    => 0,
    errortime_out => 0 ps,
    clocks        => 0
  );
  
  -- Verification signals
  signal tb_match    : boolean;
  signal tb_mismatch : boolean;
  
begin

  -----------------------------------------------------------------------------
  -- Clock generation
  -- Matches Verilog: initial forever #5 clk = ~clk;
  -----------------------------------------------------------------------------
  clk_process : process
  begin
    clk <= '0';
    wait for clk_period / 2;
    clk <= '1';
    wait for clk_period / 2;
  end process;
  
  -----------------------------------------------------------------------------
  -- Stimulus generator instantiation
  -- Matches Verilog: stimulus_gen stim1 (.clk, .*, .in);
  -----------------------------------------------------------------------------
  stim1 : entity work.stimulus_gen
    port map (
      clk       => clk,
      signal_in => signal_in,
      sim_done  => sim_done
    );
  
  -----------------------------------------------------------------------------
  -- Reference module instantiation
  -- Matches Verilog: RefModule good1 (.clk, .in, .out(out_ref));
  -----------------------------------------------------------------------------
  good1 : entity work.RefModule
    port map (
      clk        => clk,
      signal_in  => signal_in,
      signal_out => out_ref
    );
  
  -----------------------------------------------------------------------------
  -- DUT instantiation
  -- Matches Verilog: TopModule top_module1 (.clk, .in, .out(out_dut));
  -----------------------------------------------------------------------------
  top_module1 : entity work.TopModule
    port map (
      clk        => clk,
      signal_in  => signal_in,
      signal_out => signal_out
    );
  
  -----------------------------------------------------------------------------
  -- Verification logic
  -- Matches Verilog: assign tb_match = ({ out_ref } === ...)
  -----------------------------------------------------------------------------
  tb_match    <= (out_ref = signal_out);
  tb_mismatch <= not tb_match;
  
  -----------------------------------------------------------------------------
  -- Verification process
  -- Matches Verilog: always @(posedge clk, negedge clk)
  -----------------------------------------------------------------------------
  verify_process : process(clk)
  begin
    if rising_edge(clk) or falling_edge(clk) then
      -- Only count when simulation not done
      if not sim_done then
        stats1.clocks <= stats1.clocks + 1;
        
        -- Check overall match
        if not tb_match then
          if stats1.errors = 0 then
            stats1.errortime <= now;
          end if;
          stats1.errors <= stats1.errors + 1;
        end if;
        
        -- Check specific output
        -- Matches Verilog: if (out_ref !== (out_ref ^ out_dut ^ out_ref))
        if out_ref /= signal_out then
          if stats1.errors_out = 0 then
            stats1.errortime_out <= now;
          end if;
          stats1.errors_out <= stats1.errors_out + 1;
        end if;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- VUnit runner process
  -----------------------------------------------------------------------------
  test_runner : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait;  -- Wait for report process to cleanup
  end process;
  
  -----------------------------------------------------------------------------
  -- Report process
  -- Matches Verilog: final begin ... end
  -----------------------------------------------------------------------------
  report_process : process
    file f : text open write_mode is "summary.txt";
    variable l : line;
  begin
    -- Wait for timeout (matches Verilog timeout: #1000000)
    wait for 1000000 ps;
    
    -- Generate summary.txt (matches Verilog final block)
    if stats1.errors_out > 0 then
      write(l, string'("Hint: Output 'out' has "));
      write(l, stats1.errors_out);
      write(l, string'(" mismatches. First mismatch occurred at time "));
      write(l, stats1.errortime_out / 1 ps);
      write(l, string'(" ps."));
      writeline(f, l);
    else
      write(l, string'("Hint: Output 'out' has no mismatches."));
      writeline(f, l);
    end if;
    
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
    
    -- Console output (matches Verilog $display)
    info("========================================");
    if stats1.errors_out > 0 then
      info("Hint: Output 'out' has " & integer'image(stats1.errors_out) & 
           " mismatches. First mismatch at time " & 
           integer'image(stats1.errortime_out / 1 ps) & " ps.");
    else
      info("Hint: Output 'out' has no mismatches.");
    end if;
    
    info("Hint: Total mismatched samples is " & 
         integer'image(stats1.errors) & " out of " & 
         integer'image(stats1.clocks) & " samples");
    info("Simulation finished at " & integer'image(now / 1 ps) & " ps");
    info("Mismatches: " & integer'image(stats1.errors) & 
         " in " & integer'image(stats1.clocks) & " samples");
    info("========================================");
    
    -- Pass/Fail determination
    if stats1.errors > 0 then
      check_failed("FAIL: " & integer'image(stats1.errors) & 
                   " mismatches in " & integer'image(stats1.clocks) & " samples");
    else
      info("PASS: All " & integer'image(stats1.clocks) & " samples matched!");
    end if;
    
    -- Cleanup and stop
    test_runner_cleanup(runner);
    std.env.stop;
    wait;
  end process;

end architecture sim;
```

```reference
-- (3) Reference implementation (RefModule)
-- Reference Module: XOR Flip-Flop
-- D flip-flop with XOR feedback
-- out <= in XOR out (registered on rising edge of clk)
-- Variable name changes: 'in' -> 'signal_in', 'out' -> 'signal_out'

library ieee;
use ieee.std_logic_1164.all;

entity RefModule is
  port (
    clk        : in  std_logic;
    signal_in  : in  std_logic;
    signal_out : out std_logic
  );
end entity RefModule;

architecture rtl of RefModule is
  -- Matches Verilog: initial out = 0;
  signal out_reg : std_logic := '0';
begin
  
  signal_out <= out_reg;
  
  -- Matches Verilog: always@(posedge clk) out <= in ^ out;
  process(clk)
  begin
    if rising_edge(clk) then
      out_reg <= signal_in xor out_reg;
    end if;
  end process;

end architecture rtl;
```

```dut
-- (4) DUT implementation (TopModule)
-- User's design under test
-- Must implement: XOR Flip-Flop with feedback

library ieee;
use ieee.std_logic_1164.all;

entity TopModule is
  port (
    clk        : in  std_logic;
    signal_in  : in  std_logic;
    signal_out : out std_logic
  );
end entity TopModule;

architecture rtl of TopModule is
  signal out_reg : std_logic := '0';
begin
  
  signal_out <= out_reg;
  
  process(clk)
  begin
    if rising_edge(clk) then
      out_reg <= signal_in xor out_reg;
    end if;
  end process;

end architecture rtl;
```
'''

