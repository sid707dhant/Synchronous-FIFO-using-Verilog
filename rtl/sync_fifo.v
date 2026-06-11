

`timescale 1ns/1ps

module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 8,
    parameter ADDR_WIDTH = $clog2        // ceil(log2(FIFO_DEPTH))
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  wr_en,
    input  wire                  rd_en,
    input  wire [DATA_WIDTH-1:0] data_in,
    output reg  [DATA_WIDTH-1:0] data_out,
    output wire                  full,
    output wire                  empty,
    output wire [ADDR_WIDTH:0]   fifo_count
);

    // ----------------------------------------------------------
    // Internal memory array
    // ----------------------------------------------------------
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

    // ----------------------------------------------------------
    // Read / Write pointers and occupancy counter
    // ----------------------------------------------------------
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH:0]   count;

    // ----------------------------------------------------------
    // Status flags
    // ----------------------------------------------------------
    assign fifo_count = count;
    assign full       = (count == FIFO_DEPTH);
    assign empty      = (count == 0);

    // ----------------------------------------------------------
    // Sequential logic — single always block, synchronous reset
    // ----------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr   <= 0;
            rd_ptr   <= 0;
            count    <= 0;
            data_out <= 0;
        end
        else begin
            case ({wr_en & ~full, rd_en & ~empty})

                // ---- Write only --------------------------------
                2'b10: begin
                    mem[wr_ptr] <= data_in;
                    // Explicit wrap: works for ANY FIFO_DEPTH,
                    // not just powers of 2
                    wr_ptr <= (wr_ptr == FIFO_DEPTH - 1) ? 0
                                                         : wr_ptr + 1'b1;
                    count  <= count + 1'b1;
                end

                // ---- Read only ---------------------------------
                2'b01: begin
                    data_out <= mem[rd_ptr];
                    rd_ptr   <= (rd_ptr == FIFO_DEPTH - 1) ? 0
                                                           : rd_ptr + 1'b1;
                    count    <= count - 1'b1;
                end

                // ---- Simultaneous Read & Write -----------------
                // count stays the same; no overflow / underflow
                2'b11: begin
                    mem[wr_ptr] <= data_in;
                    data_out    <= mem[rd_ptr];
                    wr_ptr      <= (wr_ptr == FIFO_DEPTH - 1) ? 0
                                                              : wr_ptr + 1'b1;
                    rd_ptr      <= (rd_ptr == FIFO_DEPTH - 1) ? 0
                                                              : rd_ptr + 1'b1;
                    // count unchanged
                end

                // ---- No operation (both disabled, or both
                //      asserted but FIFO full+empty impossible) --
                default: begin
                    // intentionally empty
                end

            endcase
        end
    end

endmodule
