`timescale 1ns / 1ps 

//////////////////////////////////////////////////////////////////////////////////
// Company: University of Sheffield 
// Engineer: EBranners
// 
// Create Date: 13.02.2025
// Design Name: AES Core Module
// Module Name: aes_core
// Project Name: AES Encryption/Decryption
// Target Devices: 
// Tool Versions: Xilinx Vivado 2021.2
// Description: 
//  The AES core module implementing AES encryption and decryption with key expansion
//  and S-box handling. The module is controlled by FSM and supports both 128-bit
//  and 256-bit key lengths.
//
// Dependencies: 
//   - aes_encipher_block
//   - aes_decipher_block
//   - aes_key_mem
//   - aes_sbox
//
// Revision:
// Revision 0.02 - Improved modularity
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module aes_core( 
    input wire            clk,             // Clock signal
    input wire            reset_n,         // Active low reset signal

    input wire            encdec,          // Encryption (1) or Decryption (0)
    input wire            init,            // Initialize the AES operation
    input wire            next,            // Start next operation in sequence
    output wire           ready,           // Indicates AES is ready for next operation

    input wire [255 : 0]  key,             // 256-bit key input (128/256 bits)
    input wire            keylen,          // Key length (0 for 128-bit, 1 for 256-bit)

    input wire [127 : 0]  block,           // 128-bit input block
    output wire [127 : 0] result,          // 128-bit result after AES operation
    output wire           result_valid     // Indicates result is valid
);

// Internal Signals and Parameters
localparam CTRL_IDLE  = 2'h0;             // Idle state
localparam CTRL_INIT  = 2'h1;             // Initialization state
localparam CTRL_NEXT  = 2'h2;             // Next operation state

// Control FSM registers
reg [1 : 0] aes_core_ctrl_reg, aes_core_ctrl_new;
reg         aes_core_ctrl_we;

// Output registers
reg         result_valid_reg, result_valid_new, result_valid_we;
reg         ready_reg, ready_new, ready_we;

// Internal signals for key expansion, encryption, and decryption blocks
reg         init_state;                  // Initialization state flag
wire [127 : 0] round_key;               // Output from key expansion module
wire           key_ready;               // Indicates key expansion is ready
reg            enc_next;                // Control signal for encryption next state
wire [3 : 0]   enc_round_nr;            // Round number for encryption
wire [127 : 0] enc_new_block;           // New block after encryption
wire           enc_ready;               // Encryption block ready signal
wire [31 : 0]  enc_sboxw;               // S-box word for encryption

reg            dec_next;                // Control signal for decryption next state
wire [3 : 0]   dec_round_nr;            // Round number for decryption
wire [127 : 0] dec_new_block;           // New block after decryption
wire           dec_ready;               // Decryption block ready signal

reg [127 : 0]  muxed_new_block;         // Muxed block between encryption and decryption
reg [3 : 0]    muxed_round_nr;          // Muxed round number
reg            muxed_ready;             // Muxed ready signal

wire [31 : 0]  keymem_sboxw;            // S-box word from key memory
reg [31 : 0]   muxed_sboxw;             // Muxed S-box word
wire [31 : 0]  new_sboxw;               // New S-box word output

// AES Sub-modules: Encryption, Decryption, Key Expansion, and S-box
aes_encipher_block enc_block(
    .clk(clk),
    .reset_n(reset_n),
    .next(enc_next),
    .keylen(keylen),
    .round(enc_round_nr),
    .round_key(round_key),
    .sboxw(enc_sboxw),
    .new_sboxw(new_sboxw),
    .block(block),
    .new_block(enc_new_block),
    .ready(enc_ready)
);

aes_decipher_block dec_block(
    .clk(clk),
    .reset_n(reset_n),
    .next(dec_next),
    .keylen(keylen),
    .round(dec_round_nr),
    .round_key(round_key),
    .block(block),
    .new_block(dec_new_block),
    .ready(dec_ready)
);

aes_key_mem keymem(
    .clk(clk),
    .reset_n(reset_n),
    .key(key),
    .keylen(keylen),
    .init(init),
    .round(muxed_round_nr),
    .round_key(round_key),
    .ready(key_ready),
    .sboxw(keymem_sboxw),
    .new_sboxw(new_sboxw)
);

aes_sbox sbox_inst(
    .sboxw(muxed_sboxw),
    .new_sboxw(new_sboxw)
);

// ============================================================
// AES Core Control Logic
// ============================================================
// This section manages the AES encryption/decryption process,
// including state control, S-box selection, and data path control.
// The design ensures modularity and performance optimization.
// ============================================================

// -----------------------------
// Assign Output Signals
// -----------------------------
// The `ready` signal indicates when the AES core is ready for new input.
// The `result` signal holds the processed ciphertext/plaintext.
// The result is only valid when `result_valid` is asserted.
assign ready = ready_reg;
assign result = muxed_new_block;
assign result_valid = result_valid_reg;

// -----------------------------
// Register Update for Control and States
// -----------------------------
// This always block updates control and status registers
// on the rising edge of `clk` or asynchronously resets them.
always @(posedge clk or negedge reset_n)
begin: reg_update
    if (!reset_n) begin
        // Reset state: AES core starts in idle mode
        result_valid_reg <= 1'b0;   // No valid result initially
        ready_reg <= 1'b1;          // Core is ready for operation
        aes_core_ctrl_reg <= CTRL_IDLE; // Control FSM starts in IDLE state
    end else begin
        // Update control/status registers based on write enables
        if (result_valid_we) result_valid_reg <= result_valid_new;
        if (ready_we) ready_reg <= ready_new;
        if (aes_core_ctrl_we) aes_core_ctrl_reg <= aes_core_ctrl_new;
    end
end

// -----------------------------
// S-box Multiplexer: Key Expansion vs. Data Path
// -----------------------------
// The AES S-box is used for both key expansion and encryption operations.
// This multiplexer selects the appropriate S-box input.
always @*
begin: sbox_mux
    if (init_state)
        muxed_sboxw = keymem_sboxw;   // Use S-box for key expansion
    else
        muxed_sboxw = enc_sboxw;      // Use S-box for encryption/decryption
end

// -----------------------------
// Encryption/Decryption Multiplexer: Data Path Control
// -----------------------------
// Selects the appropriate data path depending on whether the AES core
// is performing encryption or decryption.
always @*
begin: encdec_mux
    // Default values
    enc_next = 1'b0;
    dec_next = 1'b0;

    if (encdec) begin
        // Encryption path
        enc_next = next;              // Enable encryption for next operation
        muxed_round_nr = enc_round_nr;
        muxed_new_block = enc_new_block;
        muxed_ready = enc_ready;
    end else begin
        // Decryption path
        dec_next = next;              // Enable decryption for next operation
        muxed_round_nr = dec_round_nr;
        muxed_new_block = dec_new_block;
        muxed_ready = dec_ready;
    end
end

// -----------------------------
// AES Core Control FSM
// -----------------------------
// Controls the state of the AES core, managing initialization,
// key expansion, and encryption/decryption rounds.
always @*
begin: aes_core_ctrl
    // Default values (Idle state assumptions)
    init_state = 1'b0;
    ready_new = 1'b0;
    ready_we = 1'b0;
    result_valid_new = 1'b0;
    result_valid_we = 1'b0;
    aes_core_ctrl_new = CTRL_IDLE;
    aes_core_ctrl_we = 1'b0;

    case (aes_core_ctrl_reg)
        // -----------------
        // Idle State
        // -----------------
        // Waits for a new encryption/decryption request.
        CTRL_IDLE: begin
            if (init) begin
                // Start key expansion process
                init_state = 1'b1;
                ready_new = 1'b0;      // Mark core as busy
                ready_we = 1'b1;
                result_valid_new = 1'b0;
                result_valid_we = 1'b1;
                aes_core_ctrl_new = CTRL_INIT;  // Transition to INIT state
                aes_core_ctrl_we = 1'b1;
            end else if (next) begin
                // Start encryption/decryption process
                init_state = 1'b0;
                ready_new = 1'b0;      // Mark core as busy
                ready_we = 1'b1;
                result_valid_new = 1'b0;
                result_valid_we = 1'b1;
                aes_core_ctrl_new = CTRL_NEXT;  // Transition to NEXT state
                aes_core_ctrl_we = 1'b1;
            end
        end

        // -----------------
        // Initialisation State
        // -----------------
        // Handles key expansion before encryption begins.
        CTRL_INIT: begin
            init_state = 1'b1;
            if (key_ready) begin
                // Key expansion complete, core is ready
                ready_new = 1'b1;
                ready_we = 1'b1;
                aes_core_ctrl_new = CTRL_IDLE;  // Return to idle state
                aes_core_ctrl_we = 1'b1;
            end
        end

        // -----------------
        // Next Round State
        // -----------------
        // Executes a single round of AES encryption/decryption.
        CTRL_NEXT: begin
            result_valid_new = 1'b1;  // Output data is now valid
            result_valid_we = 1'b1;
            aes_core_ctrl_new = CTRL_IDLE;  // Return to idle state
            aes_core_ctrl_we = 1'b1;
        end
    endcase
end

endmodule
