interface fifo_if #(parameter DATA_WIDTH = 8);
    
    // Signals
    logic clk;
    logic rst_n;      // Active low reset
    logic wr_en;      // Write Enable
    logic rd_en;      // Read Enable
    logic [DATA_WIDTH-1:0] wdata; // Write Data
    
    logic [DATA_WIDTH-1:0] rdata; // Read Data
    logic full;
    logic empty;

    // Modport for the DUT
    modport dut (
        input  clk, rst_n, wr_en, rd_en, wdata,
        output rdata, full, empty
    );

    // Modport for the Testbench
    modport tb (
        output clk, rst_n, wr_en, rd_en, wdata,
        input  rdata, full, empty
    );

// ------------------------------------------------------------------
    // DV NOTE: ASSERTION STRATEGY
    // ------------------------------------------------------------------
    // Ideally, this section would use Concurrent Assertions (SVA) like:
    //      assert property (@(posedge clk) ...);
    //
    // However, the standard ModelSim Student/Intel Edition disables the 
    // SVA engine (licensing restriction). 
    //
    // To ensure this testbench is fully self-checking and reproducible
    // without requiring an enterprise Questasim license, I have implemented 
    // these checks using procedural logic. This functionally verifies 
    // the same overflow/underflow protocols as SVA.
    // ------------------------------------------------------------------
    
    // 1. Overflow Check: 
    // "If we write while full (and not reading), raise an error."
    always @(posedge clk) begin
        // Only check if reset is released
        if (rst_n) begin
            
            // 1. Overflow Check
            // If writing while full (and not reading to make space)...
            if (wr_en && full && !rd_en) begin
                $error("VIOLATION: Overflow! Wrote to full FIFO.");
            end

            // 2. Underflow Check
            // If reading while empty...
            if (rd_en && empty) begin
                $error("VIOLATION: Underflow! Read from empty FIFO.");
            end
        end
    end

endinterface