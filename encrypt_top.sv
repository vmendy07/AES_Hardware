`timescale 1ns / 1ps

module encrypt_top (
    input  wire         clk,          // Clock signal
    input  wire         rst,          // Reset signal
    input  wire [127:0] plaintext,    // 128-bit input plaintext block
    input  wire [127:0] key,          // 128-bit encryption key
    output reg  [127:0] ciphertext    // 128-bit output encrypted block
);

    // Internal signals for the AES state through different rounds
    reg [127:0] state [0:10];         // States after each round (0-10)
    wire [127:0] round_keys [0:10];   // Round keys for each round
    
//    // Intermediate transformation signals
//    wire [127:0] sub_bytes_out;
//    wire [127:0] shift_rows_out;
//    wire [127:0] mix_columns_out;
    
    // Generate all round keys from the initial key
    key_expansion #(
        .KEY_WORDS(4),           // 4 words for AES-128
        .ROUNDS(10)              // 10 rounds for AES-128
    ) key_exp (
        .seed_key(key),          // Input key
        .expanded_keys(round_keys) // Output array of round keys
    );
    
    // Initial round (only AddRoundKey)
    add_roundkey initial_round (
        .state(plaintext),
        .round_key(round_keys[0]),
        .state_out(state[0])
    );
    
    // Generate the 9 main rounds
    genvar r;
generate
    for (r = 0; r < 9; r = r + 1) begin : main_rounds
        reg [127:0] sub_bytes_out_r;  // Pipelined register
        reg [127:0] shift_rows_out_r; // Pipelined register
        reg [127:0] mix_columns_out_r; // Pipelined register

        wire [127:0] sub_bytes_out_wire;
        wire [127:0] shift_rows_out_wire;
        wire [127:0] mix_columns_out_wire;
        
        // SubBytes operation
        subbytes_generic sub_bytes_r (
            .mode(1'b0),      // Forward transformation (encryption)
            .state(state[r]),
            .state_out(sub_bytes_out_wire)
        );
        
        // ShiftRows operation
        shiftrows shift_rows_r (
            .i_block(sub_bytes_out_r),
            .o_block(shift_rows_out_wire)
        );
        
        // MixColumns operation
        mixcolumns mix_columns_r (
            .i_block(shift_rows_out_r),
            .o_block(mix_columns_out_wire)
        );

        always @(posedge clk or posedge rst) begin
            if (rst) begin
                sub_bytes_out_r <= 128'b0;
                shift_rows_out_r <= 128'b0;
                mix_columns_out_r <= 128'b0;
            end else begin
                sub_bytes_out_r <= sub_bytes_out_wire;
                shift_rows_out_r <= shift_rows_out_wire;
                mix_columns_out_r <= mix_columns_out_wire;
            end
        end
        
        // AddRoundKey operation
        add_roundkey add_round_key_r (
            .state(mix_columns_out_r),
            .round_key(round_keys[r+1]),
            .state_out(state[r+1])
        );
    end
endgenerate
    

// Final round (no MixColumns)
reg [127:0] sub_bytes_out_final_r;  // Pipelined register
reg [127:0] shift_rows_out_final_r; // Pipelined register
reg valid_o;

wire [127:0] sub_bytes_out_final_wire;
wire [127:0] shift_rows_out_final_wire;

// SubBytes for final round
subbytes_generic sub_bytes_final (
    .mode(1'b0),
    .state(state[9]),
    .state_out(sub_bytes_out_final_wire)
);

// ShiftRows for final round
shiftrows shift_rows_final (
    .i_block(sub_bytes_out_final_r),
    .o_block(shift_rows_out_final_wire)
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        sub_bytes_out_final_r <= 128'b0;
        shift_rows_out_final_r <= 128'b0;
    end else begin
        sub_bytes_out_final_r <= sub_bytes_out_final_wire;
        shift_rows_out_final_r <= shift_rows_out_final_wire;
    end
end

// Final AddRoundKey
add_roundkey add_round_key_final (
    .state(shift_rows_out_final_r),
    .round_key(round_keys[10]),
    .state_out(state[10])
);

// The ciphertext is the state after the final round
always @(posedge clk or posedge rst) begin
    if (rst) 
//        ciphertext <= 128'b0;
        valid_o <= 1'b0;
     else 
//        valid_o <= 1'b1;
        ciphertext <= state[10];
    end

endmodule