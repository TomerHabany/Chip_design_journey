<h1>🌌 Log 2: The Architecture of Addition</h1>

<p align="center">
  <b>A Journey from Fresh Graduate to Silicon Engineer</b><br>
  <i>Moving from behavioral modeling to structural hardware design.</i>
</p>

<hr>

<h3>🚀 The Mission: Structural Integration</h3>
<p>In Log 2, we move from behavioral modeling (letting the tools decide the logic) to <b>Structural Modeling</b>. We are building a <b>Parameterizable Ripple Carry Adder (RCA)</b> together. This log isn't just about addition; it's about learning how to build a scalable system from small, verified sub-modules.</p>

<hr>

<h3>🧩 Part 1: The Leaf Cell (adder_1bit.sv)</h3>

<p><b>The Goal:</b><br>
We need to build a "Full Adder"—the smallest unit of addition. It takes two bits (<i>a, b</i>) and a "Carry-In" (<i>cin</i>) from a previous stage, then outputs a <i>sum</i> and a <i>cout</i>.</p>

<p><b>Breaking Down the Logic:</b><br>
To solve this, we use Boolean gates. But we also have to account for physical reality: signals don't move through gates instantly. We use <b>inertial delays</b> (<code>#1</code>) to tell the simulator to wait 1ns before updating the output.</p>

<blockquote>
  <b>⚠️ Important Note:</b> Adding <code>#1</code> makes this code <b>non-synthesizable</b>. In real production RTL, you wouldn't include these delays because the actual timing is determined by physical silicon and synthesis tools. For our simulation, they are vital for visualizing the "ripple" effect.
</blockquote>



<p><b>The Code:</b></p>
<details open>
<summary><b>📄 rtl/adder_1bit.sv</b></summary>
<pre><code>
`timescale 1ns/1ps
module adder_1bit (
    input logic  a, b, cin,
    output logic sum, cout
);
    // These #1 delays are for simulation only!
    assign #1 sum  = a ^ b ^ cin;
    assign #1 cout = (a & b) | (cin & (a ^ b));
endmodule
</code></pre>
</details>

<p><b>How this code executes the goal:</b><br>
The XOR gate (<code>^</code>) calculates the parity for the sum, while the AND/OR gates determine the overflow. By including the <code>#1</code>, we ensure the waveform shows the signal "traveling," allowing us to debug timing issues just like a real silicon engineer.</p>

<hr>

<h3>🏗️ Part 2: The Scalable Top-Level (rca.sv)</h3>

<p><b>The Goal:</b><br>
We need to chain these 1-bit adders to handle larger numbers. Instead of manually connecting 16 blocks, we want a design that scales automatically based on a single variable.</p>

<p><b>Breaking Down the Logic:</b><br>
To achieve this, we use two powerful concepts:</p>
<ol>
  <li><b>The Carry Chain:</b> Think of this as a physical wire that connects the "Carry-Out" of one bit to the "Carry-In" of the next. We define a logic net <code>[WIDTH:0] carry_chain</code> to act as this highway.</li>
  <li><b>The Generate Loop:</b> We use a <code>generate</code> block to "stamp out" our 1-bit adder as many times as the <code>WIDTH</code> parameter requires.</li>
</ol>

<blockquote>
  <b>Syntax Skeleton:</b><br>
  <code>genvar i;</code><br>
  <code>generate</code><br>
  <code>&nbsp;&nbsp;for (i=0; i < LIMIT; i=i+1) begin : block_name</code><br>
  <code>&nbsp;&nbsp;&nbsp;&nbsp;// Logic here</code><br>
  <code>&nbsp;&nbsp;end</code><br>
  <code>endgenerate</code>
</blockquote>



<p><b>The Code:</b></p>
<details open>
<summary><b>📄 rtl/rca.sv</b></summary>
<pre><code>
module rca #( parameter WIDTH = 8 ) (
    input  logic [WIDTH-1:0] a, b,
    input  logic             cin,
    output logic [WIDTH-1:0] sum,
    output logic             cout
);
    // The Carry Chain: Connecting the overflow between bits
    logic [WIDTH:0] carry_chain;
    assign carry_chain[0] = cin;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : adder_loop
            adder_1bit u_adder_1bit (
                .a   (a[i]),
                .b   (b[i]),
                .cin (carry_chain[i]),
                .sum (sum[i]),
                .cout(carry_chain[i+1])
            );
        end
    endgenerate

    assign cout = carry_chain[WIDTH];
endmodule
</code></pre>
</details>

<p><b>How this code executes the goal:</b><br>
By connecting <code>carry_chain[i]</code> to <code>carry_chain[i+1]</code>, we create a continuous path. The carry bit "ripples" from the LSB all the way to the MSB. Changing the <code>WIDTH</code> parameter now automatically updates the entire hardware structure without changing a single line of logic.</p>

<hr>

<h3>🧪 Part 3: The Automated Testbench (tb_rca.sv)</h3>

<p><b>The Goal:</b><br>
We need to verify that 16-bit math is correct without checking waveforms by hand. We want a system that alerts us immediately if a calculation fails.</p>

<p><b>Breaking Down the Logic:</b><br>
We build a <b>Self-Checking Testbench</b>. The strategy is to do the calculation twice:
<ul>
  <li>First, we run the addition through our custom <b>RCA module</b>.</li>
  <li>Second, we do the same addition using <b>SystemVerilog’s built-in + operator</b>.</li>
</ul>
Since the built-in operator is guaranteed to be mathematically correct in simulation, we compare the results. If they don't match, our hardware chain has an error.</p>

<p><b>The Code:</b></p>
<details open>
<summary><b>🧪 dv/tb_rca.sv</b></summary>
<pre><code>
initial begin
    repeat (20) begin
        a = 16'($urandom_range(0, 2**WIDTH-1));
        b = 16'($urandom_range(0, 2**WIDTH-1));
        cin = 1'($urandom_range(0, 1));

        // Calculate a reference answer using the built-in operator
        expected_value = 17'(a) + 17'(b) + 17'(cin);
        
        #20; // The "Settling Time"

        // Compare our structural hardware vs the reference result
        if (sum !== expected_value[WIDTH-1:0] || cout !== expected_value[WIDTH])
            $error("Mismatch detected! Check the carry chain timing.");
        else
            $display("PASS: %0d + %0d = %0d", a, b, {cout, sum});
    end
end
</code></pre>
</details>

<p><b>How this code executes the goal:</b><br>
The <code>#20</code> wait is our "settling time." Since each 1-bit adder has a 1ns delay, a 16-bit ripple takes 16ns to reach the end. Waiting 20ns ensures the ripple is finished before we check the answer. Casting inputs to <code>17'</code> ensures the reference math has enough headroom to hold