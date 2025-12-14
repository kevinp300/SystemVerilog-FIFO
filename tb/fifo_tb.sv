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
        forever #5 clk = ~clk; // 100MHz
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

    // --- TASKS ---
    task automatic write_fifo(input logic [DATA_WIDTH-1:0] data);
        @(posedge clk);
        #1;
        intf.wr_en = 1;
        intf.wdata = data;
        @(posedge clk);
        #1;
        intf.wr_en = 0;
    endtask

    task automatic read_fifo();
        @(posedge clk);
        #1;
        intf.rd_en = 1;
        @(posedge clk);
        #1;
        intf.rd_en = 0;
    endtask

    // NEW TASK: Simultaneous Write & Read
    task automatic write_and_read_fifo(input logic [DATA_WIDTH-1:0] data);
        @(posedge clk);
        #1;
        intf.wr_en = 1;
        intf.wdata = data;
        intf.rd_en = 1; // Read simultaneous with Write
        @(posedge clk);
        #1;
        intf.wr_en = 0;
        intf.rd_en = 0;
        // Wait one cycle for Read Data to become valid on output
        @(posedge clk); 
    endtask

    // --- SCOREBOARD QUEUE (For Random Testing) ---
    logic [DATA_WIDTH-1:0] scoreboard [$];
    logic [DATA_WIDTH-1:0] expected_data;

    // --- MAIN TEST SEQUENCE ---
    initial begin
        $display("--- SIMULATION START ---");
        
        // 1. Initial Reset
        intf.rst_n = 0; intf.wr_en = 0; intf.rd_en = 0;
        #20; intf.rst_n = 1; #10;

        // ------------------------------------------------------------
        // TEST 1: RESET ON THE FLY
        // ------------------------------------------------------------
        $display("\n[TEST] 1. Reset on the Fly (Async Reset)...");
        write_fifo(8'hAA); write_fifo(8'hBB);
        #2; intf.rst_n = 0; #2; 
        if (intf.empty == 1 && intf.full == 0) $display("[PASS] Reset cleared FIFO immediately.");
        else $error("[FAIL] Reset failed!");
        intf.rst_n = 1; @(posedge clk);

        // ------------------------------------------------------------
        // TEST 2: FLAG TEASE (EMPTY BOUNDARY)
        // ------------------------------------------------------------
        $display("\n[TEST] 2. Flag Tease (Empty Boundary)...");
        repeat(3) begin
            write_fifo(8'hA1); #1;
            if (intf.empty) $error("[FAIL] Empty flag stuck high!");
            read_fifo(); #1;
            if (!intf.empty) $error("[FAIL] Empty flag stuck low!");
        end
        $display("[PASS] Empty Flag toggles correctly.");

        // ------------------------------------------------------------
        // TEST 3: SIMULTANEOUS READ/WRITE
        // ------------------------------------------------------------
        // FIFO is Empty. Let's fill it halfway first.
        $display("\n[TEST] 3. Simultaneous Read/Write (The Traffic Jam)...");
        for(int i=0; i<8; i++) write_fifo(i); // Fill 0..7

        // Current State: Contains 8 items. Head is '0'.
        // Action: Push '0xAA' and Pop '0' at the same time.
        // Result: Should still contain 8 items. Output should be '0'.
        write_and_read_fifo(8'hAA);
        
        if (intf.rdata == 0) $display("[PASS] Simultaneous Read data matches (0).");
        else $error("[FAIL] Simultaneous Read wrong! Got %h", intf.rdata);

        // Check if count is stable (Should neither be full nor empty)
        if (!intf.full && !intf.empty) $display("[PASS] Flags stable during Simultaneous access.");
        else $error("[FAIL] Flags glitched!");

        // Empty the rest (cleanup)
        repeat(8) read_fifo(); 

        // ------------------------------------------------------------
        // TEST 4: ROLLOVER (ADDRESS WRAP)
        // ------------------------------------------------------------
        $display("\n[TEST] 4. Rollover Test (Filling past address 15)...");
        // We need to circle the track more than once.
        // 1. Fill completely (0-15)
        for (int i=0; i<16; i++) write_fifo(i);
        // 2. Empty completely (Read ptr wraps 15->0)
        for (int i=0; i<16; i++) read_fifo();
        
        // 3. Write AGAIN (Write ptr wraps 15->0)
        write_fifo(8'hCA); // "CA" for "Circle Again"
        
        if (!intf.empty) $display("[PASS] Pointers wrapped 15->0 successfully.");
        else $error("[FAIL] FIFO thinks it is empty after wrap-around write!");
        
        // Cleanup
        read_fifo();

        // ------------------------------------------------------------
        // TEST 5: RANDOMIZED STRESS (THE MONKEY TEST)
        // ------------------------------------------------------------
        $display("\n[TEST] 5. Randomized Stress Test (1000 Cycles)...");
        
        // Clear everything first
        intf.rst_n = 0; #10; intf.rst_n = 1; #10;
        scoreboard.delete();

        repeat(1000) begin
            // Randomly choose action: 0=Write, 1=Read
            bit op;

            logic [7:0] rand_data;

            op = $random; // 1 bit random
            
            // LOGIC:
            // If Op=Write AND Not Full -> Write
            // If Op=Read  AND Not Empty -> Read
            
            if (op == 0) begin // WRITE
                if (!intf.full) begin
                    rand_data = $random;
                    write_fifo(rand_data);
                    scoreboard.push_back(rand_data);
                end
            end
            else begin // READ
                if (!intf.empty) begin
                    read_fifo();
                    expected_data = scoreboard.pop_front();
                    if (intf.rdata !== expected_data) begin
                        $error("[FAIL] Mismatch! Exp: %h, Got: %h", expected_data, intf.rdata);
                    end
                end
            end
        end
        $display("[PASS] Survived 1000 random cycles without data corruption.");

        $display("--- SIMULATION DONE ---");
        $finish;
    end

endmodule