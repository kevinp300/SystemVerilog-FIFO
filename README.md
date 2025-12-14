## Theory of Operation

### Memory Architecture (Circular Buffer)
The core of this FIFO is a **16x8 Memory Array**, acting as a circular buffer. While physically implemented as a register file or RAM, logically it functions as a stack where data is written sequentially.

* **Depth:** 16 slots (Addresses 4'b0000 to 4'b1111).
* **Width:** 8 bits (1 byte per slot).

### Data Flow Visualization
To understand the pointer movement, consider the following snapshot of the memory array during operation.

**State: Partially Filled FIFO**
In this example, the FIFO contains valid data in slots 0-3. The `rd_ptr` (Read Pointer) is currently at address 0, ready to read the oldest data. The `wr_ptr` (Write Pointer) is at address 4, pointing to the next empty slot.

```text
         ADDRESS       |           DATA CONTENTS (8 bits wide)
      (Pointer Value)  |  [7] [6] [5] [4] [3] [2] [1] [0]
      -----------------+-----------------------------------
mem[0]   4'b0000       |   0   1   0   1   1   0   1   0   <-- Read Pointer (Start of valid data)
mem[1]   4'b0001       |   1   1   1   1   0   0   0   0
mem[2]   4'b0010       |   0   0   0   0   1   1   1   1
mem[3]   4'b0011       |   1   0   1   0   1   0   1   0
mem[4]   4'b0100       |   X   X   X   X   X   X   X   X   <-- Write Pointer (Next empty slot)
mem[5]   4'b0101       |   X   X   X   X   X   X   X   X
  ...      ...         |              ...
mem[15]  4'b1111       |   X   X   X   X   X   X   X   X

