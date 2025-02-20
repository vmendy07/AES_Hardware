module shiftrows #(
    parameter NB   = 4,      // Number of columns (matrix is NB x NB)
    parameter WORD = 8       // Size of each byte in bits
)(
    input  logic               clk,
    input  logic               rst,      // Active high reset
    input  logic               i_valid,
    input  logic [NB*NB*WORD-1:0] i_block, // 128-bit input state
    output logic               o_valid,
    output logic [NB*NB*WORD-1:0] o_block  // 128-bit output state
);

    // Extract 16 bytes from the 128-bit input
    // Assuming column-major order:
    // i_block = { b0, b1, b2, b3,  b4, b5, b6, b7,  b8, b9, b10, b11,  b12, b13, b14, b15 }
    // where:
    // b0 = S[0,0], b1 = S[1,0], b2 = S[2,0], b3 = S[3,0],
    // b4 = S[0,1], b5 = S[1,1], b6 = S[2,1], b7 = S[3,1],
    // b8 = S[0,2], b9 = S[1,2], b10 = S[2,2], b11 = S[3,2],
    // b12 = S[0,3], b13 = S[1,3], b14 = S[2,3], b15 = S[3,3].

    wire [WORD-1:0] b0  = i_block[127:120];
    wire [WORD-1:0] b1  = i_block[119:112];
    wire [WORD-1:0] b2  = i_block[111:104];
    wire [WORD-1:0] b3  = i_block[103:96];
    wire [WORD-1:0] b4  = i_block[95:88];
    wire [WORD-1:0] b5  = i_block[87:80];
    wire [WORD-1:0] b6  = i_block[79:72];
    wire [WORD-1:0] b7  = i_block[71:64];
    wire [WORD-1:0] b8  = i_block[63:56];
    wire [WORD-1:0] b9  = i_block[55:48];
    wire [WORD-1:0] b10 = i_block[47:40];
    wire [WORD-1:0] b11 = i_block[39:32];
    wire [WORD-1:0] b12 = i_block[31:24];
    wire [WORD-1:0] b13 = i_block[23:16];
    wire [WORD-1:0] b14 = i_block[15:8];
    wire [WORD-1:0] b15 = i_block[7:0];

    // Apply the ShiftRows transformation.
    // For each row r, the new value is S'[r][c] = S[r][(c + r) mod 4].
    // When re-flattened into column-major order, we get:
    // Column 0: S'[0,0]=b0, S'[1,0]=b5, S'[2,0]=b10, S'[3,0]=b15
    // Column 1: S'[0,1]=b4, S'[1,1]=b9, S'[2,1]=b14, S'[3,1]=b3
    // Column 2: S'[0,2]=b8, S'[1,2]=b13, S'[2,2]=b2, S'[3,2]=b7
    // Column 3: S'[0,3]=b12, S'[1,3]=b1, S'[2,3]=b6, S'[3,3]=b11

    wire [NB*NB*WORD-1:0] shift_result;
    assign shift_result = { b0,  b5,  b10, b15,   // Column 0
                            b4,  b9,  b14, b3,    // Column 1
                            b8,  b13, b2,  b7,    // Column 2
                            b12, b1,  b6,  b11 }; // Column 3

    // Register the output and pass the valid signal
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            o_block <= '0;
            o_valid <= 1'b0;
        end else begin
            o_block <= shift_result;
            o_valid <= i_valid;
        end
    end

endmodule 