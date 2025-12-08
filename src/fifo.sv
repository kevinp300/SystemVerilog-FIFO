module fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
)(
    input  logic clk,
    input  logic rst_n,
    input  logic wr_en,
    input  logic rd_en,
    input  logic [DATA_WIDTH-1:0] wdata,
    
    output logic [DATA_WIDTH-1:0] rdata,
    output logic full,
    output logic empty
);

    // Memory Array
    logic [DATA_WIDTH-1:0] mem [FIFO_DEPTH-1:0];

    // Pointers (Width = log2(DEPTH) + 1 extra bit for wrap detection)
    localparam PTR_WIDTH = $clog2(FIFO_DEPTH);
    logic [PTR_WIDTH:0] wr_ptr;
    logic [PTR_WIDTH:0] rd_ptr;

    // --- WRITE LOGIC ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
        end else if (wr_en && !full) begin
            mem[wr_ptr[PTR_WIDTH-1:0]] <= wdata;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // --- READ LOGIC ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= '0;
        end else if (rd_en && !empty) begin
            rdata <= mem[rd_ptr[PTR_WIDTH-1:0]];
            rd_ptr <= rd_ptr + 1;
        end
    end

    // --- FLAGS LOGIC ---
    // Empty: Pointers are identical
    assign empty = (wr_ptr == rd_ptr);

    // Full: Pointers match in index (lower bits) but differ in wrap bit (MSB)
    assign full  = (wr_ptr[PTR_WIDTH-1:0] == rd_ptr[PTR_WIDTH-1:0]) && 
                   (wr_ptr[PTR_WIDTH] != rd_ptr[PTR_WIDTH]);

endmodule