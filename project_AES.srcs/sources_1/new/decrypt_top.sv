`timescale 1ns / 1ps
// this module takes 49 clk cyles to get an output 

module decrypt_top (
    input  wire         clk,          // Clock signal
    input  wire         rst,          // Reset signal
    input  wire         input_valid,   // Input valid signal
    input  wire [127:0] ciphertext,   // 128-bit input ciphertext block
    input  wire [127:0] key,          // 128-bit decryption key
    output reg  [127:0] plaintext,     // 128-bit output decrypted block
    output reg          data_valid 
);

    // Internal signals for the AES state through different rounds
    logic [127:0] round_keys [0:10];   // Round keys for each round
    
    // Add registers for pipelining between rounds
    reg [127:0] state_reg [0:10];     // Registered states between rounds

    // Data valid signal and pipeline counter
//    reg [5:0] pipeline_counter; // 6 bits is enough for 49
//    reg data_valid;

    // Data valid shift register for pipeline tracking
    reg [48:0] valid_shift_reg; // 49-stage pipeline

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_shift_reg <= 49'b0;
            data_valid <= 1'b0;
        end else begin
            valid_shift_reg <= {valid_shift_reg[47:0], input_valid};
            data_valid <= valid_shift_reg[48];
        end
    end

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
    wire [127:0] state_init;
    add_roundkey initial_round (
        .state(ciphertext),
        .round_key(round_keys[0]),
        .state_out(state_init)
    );

    // Register the output of the initial round
    always @(posedge clk or posedge rst) begin
        if (rst)
            state_reg[0] <= 128'b0;
        else
            state_reg[0] <= state_init;
    end
    
    // Main rounds: fully pipelined
    genvar r;
    generate
        for (r = 1; r < 10; r = r + 1) begin : main_rounds
            // Pipeline registers for each stage
            reg [127:0] inv_shift_rows_reg;
            reg [127:0] inv_sub_bytes_reg;
            reg [127:0] add_round_key_reg;
            reg [127:0] inv_mix_columns_reg;

            wire [127:0] inv_shift_rows_out;
            wire [127:0] inv_sub_bytes_out;
            wire [127:0] add_round_key_out;
            wire [127:0] inv_mix_columns_out;

            // InvShiftRows operation
            inv_shiftrows u_inv_shiftrows (
                .i_block(state_reg[r-1]),
                .o_block(inv_shift_rows_out)
            );
            always @(posedge clk or posedge rst) begin
                if (rst)
                    inv_shift_rows_reg <= 128'b0;
                else
                    inv_shift_rows_reg <= inv_shift_rows_out;
            end

            // InvSubBytes operation
            subbytes_generic u_inv_subbytes (
                .mode(1'b1),
                .state(inv_shift_rows_reg),
                .state_out(inv_sub_bytes_out)
            );
            always @(posedge clk or posedge rst) begin
                if (rst)
                    inv_sub_bytes_reg <= 128'b0;
                else
                    inv_sub_bytes_reg <= inv_sub_bytes_out;
            end

            // AddRoundKey operation
            add_roundkey u_add_roundkey (
                .state(inv_sub_bytes_reg),
                .round_key(round_keys[r]),
                .state_out(add_round_key_out)
            );
            always @(posedge clk or posedge rst) begin
                if (rst)
                    add_round_key_reg <= 128'b0;
                else
                    add_round_key_reg <= add_round_key_out;
            end

            // InvMixColumns operation
            inv_mixcolumns u_inv_mixcolumns (
                .i_block(add_round_key_reg),
                .o_block(inv_mix_columns_out)
            );
            always @(posedge clk or posedge rst) begin
                if (rst)
                    inv_mix_columns_reg <= 128'b0;
                else
                    inv_mix_columns_reg <= inv_mix_columns_out;
            end

            // Register the output of this round for the next round
            always @(posedge clk or posedge rst) begin
                if (rst)
                    state_reg[r] <= 128'b0;
                else
                    state_reg[r] <= inv_mix_columns_reg;
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
        .i_block(state_reg[9]),
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
        .state_out(state_reg[10])
    );
    
     // Register the output of the final round
    always @(posedge clk or posedge rst) begin
        if (rst)
            state_reg[10] <= 128'b0;
        else
            state_reg[10] <= state_reg[10];
    end   

    // The plaintext is the state after the final round
    always @(posedge clk or posedge rst) begin
        if (rst) 
            plaintext <= 128'b0;
        else 
            plaintext <= state_reg[10];
    end

endmodule