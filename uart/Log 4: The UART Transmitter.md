Yes, if you change the format to **Markdown (.md)**, GitHub will automatically render it as a formatted webpage when you click on the file in your repository. You won't need to configure GitHub Pages or use external previewers.

However, you **will** need to update the syntax slightly for the images and code blocks to work within the Markdown standard.

### Where to save the images?

To keep your Git repository clean, you should create an `images` folder. Your file structure in VS Code should look like this:

* `log4.md`
* `images/`
* `image1.png`
* `image2.png`
* `image3.png`
* `image4.png`



---

### The Updated Markdown Code

Copy and paste this into your `log4.md` file. I have adjusted the image paths to `images/imageX.png`.

```markdown
# Log 4: The UART Transmitter – Precision Timing & State Machines

In our previous log, we mastered data buffering with the FIFO. Now, we will build the bridge that sends that data out of our chip. We are moving into communication protocols, starting with the UART (Universal Asynchronous Receiver-Transmitter). Specifically, we will focus on the Transmitter (TX) side.

## What is a UART?
UART will be the "translator" of our digital world. [cite_start]Inside our chip, the CPU [cite: 1] works with parallel data—sending 8 bits all at once across 8 wires. However, most external devices only have one wire to listen on. Our UART’s job will be to take that parallel byte and "serialize" it, sending it out bit-by-bit over time.

### The Life of a Transmission: A Step-by-Step Example
Imagine our CPU wants to send the letter 'A' (ASCII 8'h41, or binary 01000001). Here is exactly how we will handle the flow:

1. [cite_start]**The Trigger:** The CPU will place 8'b01000001 on the din bus [cite: 4, 17] [cite_start]and pulse tx_start[cite: 3, 18].
2. [cite_start]**The Wake-up (Start Bit):** The UART will immediately pull the tx_out line [cite: 10, 20] [cite_start]from High to Low ('0')[cite: 27]. [cite_start]This tells the receiver[cite: 11], "Pay attention, data is coming!"
3. **The Data Payload:** The UART will then send each bit of the 'A' one by one. It will start with the Least Significant Bit (LSB) and end with the MSB.
4. [cite_start]**The Close (Stop Bit):** After all 8 bits are sent, the UART will pull the line back to High ('1')[cite: 58]. This resets the line for the next message.
5. [cite_start]**The Finish Line:** The UART will pulse tx_done [cite: 2, 21, 23] to let the CPU know it can send the next character.

Every transmission will follow this '0' -> Data -> '1' frame.

### Controlling the Timing: The 16x Over-Sampling Concept
How will we ensure the receiver doesn't miss a bit? We will use a concept called Over-sampling. [cite_start]We won't just send a bit and hope for the best; we will divide the time for a single bit (the Bit Period) into 16 smaller segments called sample_tick pulses[cite: 6, 19, 34].

[cite_start]Our UART will hold the value of each bit on tx_out for exactly 16 of these ticks[cite: 43, 60]. We do this because the receiver on the other end is designed to wait for the 8th tick—the dead center of the bit—to sample the value. [cite_start]By holding our bit for 16 ticks, we give the receiver the best possible chance to capture the data accurately[cite: 44].

![Block Diagram](images/image1.png)
*This diagram shows the high-level flow from the CPU, through our UART and Baud Generator blocks, out to the Receiver.*

---

## Deep Dive 1: The Baud Rate Generator
To get those 16 ticks per bit, we will need a heartbeat. [cite_start]This will be our Baud Rate Generator[cite: 5].

### The Logic: Why we won't let it run free
[cite_start]We don't want our baud_gen to be free-running; instead, we want it to only be enabled when a transmission starts[cite: 26].

If the generator is free-running, it is constantly counting in the background. [cite_start]If the tx_start signal arrives just as the generator was about to finish a count, our first bit (the Start Bit) might be cut extremely short[cite: 37, 38]. [cite_start]In a worst-case scenario, the '0' bit that signals the start of communication would only be a few clock cycles wide instead of the full 16-tick period[cite: 39, 43]. This would cause the receiver to miss the message entirely. [cite_start]By using a baud_en signal [cite: 13, 24] from the UART, we will "reset" the timer so it starts fresh at the exact moment we begin sending data.

![Timing Diagram](images/image2.png)
*This illustrates the timing collision that happens if we don't synchronize the generator.*

### Implementation: Step-by-Step

**Step 1: Defining the Interface and the Math**
We will start by defining our parameters. We need the CLOCK_FREQ of our board and the BAUD_RATE we want to achieve.

<details>
<summary>View Code Snippet</summary>

```systemverilog
module baud_gen #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE  = 115200
)(
    input  logic clk, rst_n, en,
    output logic sample_tick
);
    localparam TICK_LIMIT = CLOCK_FREQ / (BAUD_RATE * 16);
    logic [$clog2(TICK_LIMIT)-1:0] count;

```

</details>

**Step 2: The Counting Logic**
When en is high, the counter will increment. Once it hits the TICK_LIMIT, it will pulse the sample_tick for exactly one clock cycle and wrap back to zero.

<details>
<summary>View Code Snippet</summary>

```systemverilog
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            sample_tick <= 0;
        end else if (en) begin
            if (count == TICK_LIMIT - 1) begin
                count <= 0;
                sample_tick <= 1;
            end else begin
                count <= count + 1'b1;
                sample_tick <= 0;
            end
        end else begin
            count <= 0;
            sample_tick <= 0;
        end
    end
endmodule

```

</details>

---

## Deep Dive 2: The UART TX Controller

Now that we have our baud_gen to control the timing, we can start working on the UART_TX  itself.

### Designing for Stability: The Registered Moore Machine

We will implement a Moore State Machine. To ensure our output is perfectly stable and free of combinational logic "glitches," we will make it a Registered State Machine. This means we will use a state register to hold the state, ensuring that the tx_out signal only changes exactly on the clock edge.

Our architecture for latching the next state into the state register to maintain stability.

### The Philosophy of Registered State Machines

For every signal that controls our output—the state, the data buffer, and internal counters—we will create a `_next` (combinational) and a `_reg` (sequential) pair.

* **Combinational Logic (`_next`):** This acts as the "brain," calculating the next value based on current inputs.
* **Sequential Logic (`_reg`):** This acts as the "memory," latching those values exactly on the clock edge.

### Engineering Specification: `uart_tx.sv`

#### 1. Parameters and Ports

```systemverilog
module uart_tx
#(
    parameter TICKS_PER_BIT = 16, 
    parameter DATA_WIDTH    = 8   
)
(
    input  logic clk,
    input  logic rst_n,
    input  logic [DATA_WIDTH-1:0] din,
    input  logic tx_start,
    input  logic sample_tick,
    output logic tx_out,
    output logic tx_done,
    output logic baude_en
);

```

#### 2. State Machine Logic

We will implement the sequencer  using a `case` statement. Our controller will follow the pre-determined path: `IDLE` -> `START` -> `DATA` -> `STOP`. In each state, we will count 16 `sample_tick` pulses before moving to the next. In the `DATA` state, we will use the right-shift operator to move the next bit into position.

The visual sequence of our UART states.

### Complete Code: `uart_tx.sv`

<details>
<summary>Click to expand full code</summary>

```systemverilog
`timescale 1ns / 1ps
module uart_tx
#(
    parameter TICKS_PER_BIT = 16, 
    parameter DATA_WIDTH    = 8   
)
(
    input  logic clk,
    input  logic rst_n,
    input  logic [DATA_WIDTH-1:0] din,
    input  logic tx_start,
    input  logic sample_tick,
    output logic tx_out,
    output logic tx_done,
    output logic baude_en
);

    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;

    state_t state_next;
    state_t state_reg;

    logic tx_next; 
    logic tx_reg; 
    logic tx_done_next;
    logic tx_done_reg;
    logic baude_en_next;
    logic baude_en_reg;

    logic [$clog2(TICKS_PER_BIT)-1:0] tick_count_next; 
    logic [$clog2(TICKS_PER_BIT)-1:0] tick_count_reg; 
    logic [$clog2(DATA_WIDTH)-1:0] bit_count_next; 
    logic [$clog2(DATA_WIDTH)-1:0] bit_count_reg; 
    logic [DATA_WIDTH-1:0] tx_data_next; 
    logic [DATA_WIDTH-1:0] tx_data_reg; 

    assign tx_out   = tx_reg;
    assign tx_done  = tx_done_reg;
    assign baude_en = baude_en_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_reg      <= IDLE;
            tx_reg         <= 1'b1;
            tick_count_reg <= '0;
            bit_count_reg  <= '0;
            tx_data_reg    <= '0;
            tx_done_reg    <= 1'b0;
            baude_en_reg   <= 1'b0;
        end else begin
            state_reg      <= state_next;
            tx_reg         <= tx_next;
            tick_count_reg <= tick_count_next;
            bit_count_reg  <= bit_count_next;
            tx_data_reg    <= tx_data_next;
            tx_done_reg    <= tx_done_next;
            baude_en_reg   <= baude_en_next;
        end
    end

    always_comb begin
         state_next      = state_reg;
         tx_next         = tx_reg;
         tick_count_next = tick_count_reg;
         bit_count_next  = bit_count_reg;
         tx_data_next    = tx_data_reg;
         tx_done_next    = 1'b0; 
         baude_en_next   = (state_reg != IDLE);

         case(state_reg)
            IDLE: begin
                tx_next = 1'b1;
                if (tx_start) begin
                    state_next      = START;
                    tx_data_next    = din;
                    tick_count_next = '0;
                end
            end   

            START: begin
                tx_next = 1'b0;
                if (sample_tick) begin
                    if (tick_count_reg == TICKS_PER_BIT - 1) begin
                        state_next      = DATA;
                        tick_count_next = '0;
                        bit_count_next  = '0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end

            DATA: begin 
                tx_next = tx_data_reg[0];
                if (sample_tick) begin
                    if (tick_count_reg == TICKS_PER_BIT - 1) begin
                        tick_count_next = '0;
                        if (bit_count_reg == DATA_WIDTH - 1) begin
                            state_next     = STOP;
                            bit_count_next = '0;
                        end else begin
                            bit_count_next = bit_count_reg + 1;
                            tx_data_next   = tx_data_reg >> 1;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end

            STOP: begin
                tx_next = 1'b1;
                if (sample_tick) begin
                    if (tick_count_reg == TICKS_PER_BIT - 1) begin
                        state_next      = IDLE;
                        tx_done_next    = 1'b1;
                        tick_count_next = '0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
         endcase
    end
endmodule

```

</details>

```

### Final Step:

1.  Save the code above as `log4.md`.
2.  Make sure your 4 images are in a folder named `images`.
3.  Push to Git. GitHub will now show the formatted text and the diagrams automatically when you open the `.md` file.

Would you like me to explain how to customize the theme of this Markdown log if you decide to use it for a portfolio later?

```