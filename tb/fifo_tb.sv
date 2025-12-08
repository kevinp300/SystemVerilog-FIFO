`timescale 1ns/1ps

module fifo_tb;

    localparam DATA_WIDTH = 8;
    localparam FIFO_DEPTH = 16;

    // Interface
    fifo_if #(DATA_WIDTH) intf();

    // Clock Gen
    logic clk;
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns Period = 100MHz
    end
    assign intf.clk = clk;

    // DUT Instance
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk(intf.clk),
        .rst_n(intf.rst_n),
        .wr_en(intf.wr_en),
        .rd_en(intf.rd_en),
        .wdata(intf.wdata),
        .rdata(intf.rdata),
        .full(intf.full),
        .empty(intf.empty)
    );

    // --- TASKS (For clean verification) ---
    task automatic write_fifo(input logic [DATA_WIDTH-1:0] data);
        @(posedge clk);
        intf.wr_en = 1;
        intf.wdata = data;
        @(posedge clk);
        intf.wr_en = 0;
    endtask

    task automatic read_fifo();
        @(posedge clk);
        intf.rd_en = 1;
        @(posedge clk);
        intf.rd_en = 0;
    endtask

    // --- MAIN TEST ---
    initial begin
        $display("--- SIMULATION START ---");
        
        // 1. Reset
        intf.rst_n = 0; intf.wr_en = 0; intf.rd_en = 0;
        #20;
        intf.rst_n = 1;
        #10;

        // 2. Fill FIFO (0 to 15)
        $display("[TEST] Filling FIFO...");
        for (int i=0; i<FIFO_DEPTH; i++) begin
            write_fifo(i);
        end
        
        // Check Full Flag
        #1;
        if (intf.full) $display("[PASS] FIFO is Full.");
        else           $error("[FAIL] FIFO should be Full!");

        // 3. Attempt Overflow (The "Breaker" Test)
        $display("[TEST] Attempting Overflow Write...");
        write_fifo(8'hFF); 
        // Note: The Assertion in the Interface should trigger an error here
        
        // 4. Empty FIFO
        $display("[TEST] Emptying FIFO...");
        for (int i=0; i<FIFO_DEPTH; i++) begin
            read_fifo();
        end

        // Check Empty Flag
        #1;
        if (intf.empty) $display("[PASS] FIFO is Empty.");
        else            $error("[FAIL] FIFO should be Empty!");

        $display("--- SIMULATION DONE ---");
        $finish;
    end

endmodule