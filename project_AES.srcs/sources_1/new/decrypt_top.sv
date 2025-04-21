`timescale 1ns / 1ps

module decrypt_top (
    input  wire         clk,          // Clock signal
    input  wire         rst,          // Reset signal
    input  wire [127:0] ciphertext,   // 128-bit input ciphertext block
    input  wire [127:0] key,          // 128-bit decryption key
    output reg  [127:0] plaintext     // 128-bit output decrypted block
);

    // Internal signals for the AES state through different rounds
    reg [127:0] state [0:10];         // States after each round (0-10)
    logic [127:0] round_keys [0:10];   // Round keys for each round
    
    // Generate all round keys from the initial key
    key_expansion #(
        .KEY_WORDS(4),           // 4 words for AES-128
        .ROUNDS(10)              // 10 rounds for AES-128
    ) key_exp (
        .encrypt(1'b0),          // Decryption mode
        .seed_key(key),          // Input key
        .expanded_keys(round_keys) // Output array of round keys
    );
    
    // Initial round (only AddRoundKey)
    add_roundkey initial_round (
        .state(ciphertext),
        .round_key(round_keys[0]),
        .state_out(state[0])
    );
    
    // Generate the 9 main rounds
    genvar r;
    generate
        for (r = 1; r < 10; r = r + 1) begin : main_rounds
            reg [127:0] inv_shift_rows_out_r; // Pipelined register
            reg [127:0] inv_sub_bytes_out_r;  // Pipelined register
            reg [127:0] inv_mix_columns_out_r; // Pipelined register

            wire [127:0] inv_shift_rows_out_wire;
            wire [127:0] inv_sub_bytes_out_wire;
            wire [127:0] inv_mix_columns_out_wire;
            
            // InvShiftRows operation
            inv_shiftrows inv_shift_rows_r (
                .i_block(state[r-1]),
                .o_block(inv_shift_rows_out_wire)
            );
            
            // InvSubBytes operation
            subbytes_generic inv_sub_bytes_r (
                .mode(1'b1),      // Inverse transformation (decryption)
                .state(inv_shift_rows_out_r),
                .state_out(inv_sub_bytes_out_wire)
            );
            
             // AddRoundKey operation
            add_roundkey add_round_key_r (
                .state(inv_sub_bytes_out_r),
                .round_key(round_keys[r]),
                .state_out(inv_mix_columns_out_wire)
            );

            // InvMixColumns operation
            inv_mixcolumns inv_mix_columns_r (
                .i_block(inv_mix_columns_out_wire),
                .o_block(state[r])
            );
            

            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    inv_shift_rows_out_r <= 128'b0;
                    inv_sub_bytes_out_r <= 128'b0;
                    inv_mix_columns_out_r <= 128'b0;
                end else begin
                    inv_shift_rows_out_r <= inv_shift_rows_out_wire;
                    inv_sub_bytes_out_r <= inv_sub_bytes_out_wire;
                    inv_mix_columns_out_r <= inv_mix_columns_out_wire;
                end
            end
            

        end
    endgenerate
    
    // Final round (no InvMixColumns)
    reg [127:0] inv_shift_rows_out_final_r; // Pipelined register
    reg [127:0] inv_sub_bytes_out_final_r;  // Pipelined register

    wire [127:0] inv_shift_rows_out_final_wire;
    wire [127:0] inv_sub_bytes_out_final_wire;

    // InvShiftRows for final round
    inv_shiftrows inv_shift_rows_final (
        .i_block(state[9]),
        .o_block(inv_shift_rows_out_final_wire)
    );

    // InvSubBytes for final round
    subbytes_generic inv_sub_bytes_final (
        .mode(1'b1),
        .state(inv_shift_rows_out_final_r),
        .state_out(inv_sub_bytes_out_final_wire)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            inv_shift_rows_out_final_r <= 128'b0;
            inv_sub_bytes_out_final_r <= 128'b0;
        end else begin
            inv_shift_rows_out_final_r <= inv_shift_rows_out_final_wire;
            inv_sub_bytes_out_final_r <= inv_sub_bytes_out_final_wire;
        end
    end

    // Final AddRoundKey
    add_roundkey add_round_key_final (
        .state(inv_sub_bytes_out_final_r),
        .round_key(round_keys[10]),
        .state_out(state[10])
    );

    // The plaintext is the state after the final round
    always @(posedge clk or posedge rst) begin
        if (rst) 
            plaintext <= 128'b0;
        else 
            plaintext <= state[10];
    end

endmodule