

`timescale 1ns/1ps

module tb_sync_fifo;

    // ----------------------------------------------------------
    // Parameters (must match DUT)
    // ----------------------------------------------------------
    parameter DATA_WIDTH = 8;
    parameter FIFO_DEPTH = 8;
    parameter ADDR_WIDTH = 3;

    // ----------------------------------------------------------
    // Signal declarations
    // ----------------------------------------------------------
    reg                  clk;
    reg                  rst;
    reg                  wr_en;
    reg                  rd_en;
    reg  [DATA_WIDTH-1:0] data_in;

    wire [DATA_WIDTH-1:0] data_out;
    wire                  full;
    wire                  empty;
    wire [ADDR_WIDTH:0]   fifo_count;

    // ----------------------------------------------------------
    // DUT instantiation
    // ----------------------------------------------------------
    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk        (clk),
        .rst        (rst),
        .wr_en      (wr_en),
        .rd_en      (rd_en),
        .data_in    (data_in),
        .data_out   (data_out),
        .full       (full),
        .empty      (empty),
        .fifo_count (fifo_count)
    );

    // ----------------------------------------------------------
    // Clock generation — 10 ns period (100 MHz)
    // ----------------------------------------------------------
    initial clk = 0;
    always  #5 clk = ~clk;

    // ----------------------------------------------------------
    // Waveform dump (opens fifo_wave.vcd for GTKWave / EPWave)
    // ----------------------------------------------------------
    initial begin
        $dumpfile("fifo_wave.vcd");
        $dumpvars(0, tb_sync_fifo);
    end

    // ----------------------------------------------------------
    // Stimulus
    // ----------------------------------------------------------
    initial begin
        // ---- Initialise all inputs ---------------------------
        rst     = 1;
        wr_en   = 0;
        rd_en   = 0;
        data_in = 0;

        // Hold reset for 2 full clock cycles
        #20;
        rst = 0;

        // ---- Test 1 : Write 5 values (10, 20, 30, 40, 50) ---
        $display("\n--- TEST 1: Writing 5 values ---");
        repeat(5) begin
            @(posedge clk);
            wr_en   = 1;
            data_in = data_in + 8'd10;
        end
        @(posedge clk);        // deassert after last write
        wr_en = 0;

        // ---- Test 2 : Read back all 5 values -----------------
        $display("\n--- TEST 2: Reading 5 values ---");
        repeat(5) begin
            @(posedge clk);
            rd_en = 1;
        end
        @(posedge clk);        // deassert after last read
        rd_en = 0;

        // ---- Test 3 : Simultaneous Read & Write --------------
        $display("\n--- TEST 3: Simultaneous Read & Write ---");
        // First write one entry so the FIFO is not empty
        @(posedge clk);
        wr_en   = 1;
        data_in = 8'd55;
        @(posedge clk);
        wr_en = 0;

        // Now do simultaneous R/W
        @(posedge clk);
        wr_en   = 1;
        rd_en   = 1;
        data_in = 8'd99;
        @(posedge clk);
        wr_en = 0;
        rd_en = 0;

        // ---- Test 4 : Overflow attempt (write to full FIFO) --
        $display("\n--- TEST 4: Fill FIFO then attempt overflow ---");
        repeat(FIFO_DEPTH) begin
            @(posedge clk);
            wr_en   = 1;
            data_in = data_in + 8'd1;
        end
        // One extra write — should be ignored (full asserted)
        @(posedge clk);
        wr_en   = 1;
        data_in = 8'hFF;
        @(posedge clk);
        wr_en = 0;

        // ---- Test 5 : Underflow attempt (read from empty) ----
        $display("\n--- TEST 5: Drain FIFO then attempt underflow ---");
        repeat(FIFO_DEPTH) begin
            @(posedge clk);
            rd_en = 1;
        end
        // One extra read — should be ignored (empty asserted)
        @(posedge clk);
        rd_en = 1;
        @(posedge clk);
        rd_en = 0;

        // ---- End of simulation -------------------------------
        #50;
        $display("\n--- Simulation complete ---");
        $finish;
    end

    // ----------------------------------------------------------
    // Monitor — prints every signal change automatically
    // ----------------------------------------------------------
    initial begin
        $monitor("Time=%0t | wr=%b rd=%b | din=%3d dout=%3d | count=%0d | full=%b empty=%b",
                 $time, wr_en, rd_en,
                 data_in, data_out,
                 fifo_count, full, empty);
    end

endmodule
