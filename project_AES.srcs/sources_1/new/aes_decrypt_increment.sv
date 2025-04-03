`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.03.2025 12:24:30
// Design Name: 
// Module Name: aes_decrypt_increment
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module aes_decrypt_round_test (
    input  logic         clk,
    input  logic         rst,         // Active-high reset
    input  logic         i_start,     // Start signal
    input  logic [127:0] i_state,     // Input state (ciphertext or intermediate state)
    input  logic [127:0] seed_key,    // Original AES key for key expansion
    output logic [127:0] o_state,     // Output state after one round
    output logic         o_valid      // Output valid signal
);

  //-------------------------------------------------------------------------
  // Internal registers
  //-------------------------------------------------------------------------
  reg [127:0] state_reg;        // Current state
  reg [127:0] reg_inv_sub;      // Inverse SubBytes output
  reg [127:0] reg_inv_shift;    // Inverse ShiftRows output
  reg [127:0] reg_mix_col;      // Inverse MixColumns output
  reg [127:0] reg_add_r;        // Final AddRoundKey output
  reg [127:0] reg_final;        // Final AddRoundKey output

  reg [3:0] round_counter;      // Round counter

  //-------------------------------------------------------------------------
  // Wire connections for submodules
  //-------------------------------------------------------------------------
  wire [127:0] inv_sub_out;
  wire [127:0] inv_shift_out;
  wire [127:0] mix_out;
  
  logic o_valid_inv_sub;
  logic o_valid_inv_shift;
  logic o_valid_mix;

  //-------------------------------------------------------------------------
  // Key Expansion Integration
  //-------------------------------------------------------------------------
  logic [127:0] round_keys [0:10];  // Stores all round keys (AES-128 has 10 rounds)

  aes_key_expansion key_expansion_inst (
      .seed_key(seed_key),      // Original key
      .expanded_keys(round_keys) // Output expanded keys
  );

  // Select the correct round key for decryption (reverse order)
  wire [127:0] round_key = round_keys[10 - round_counter];  

  //-------------------------------------------------------------------------
  // Step 1: Apply initial AddRoundKey (XOR with last round key first)
  //-------------------------------------------------------------------------
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      state_reg <= 128'd0;
      round_counter <= 10;  // Decryption starts at round 10
    end else if (i_start) begin
      state_reg <= i_state ^ round_keys[10]; // Start with final round key
    end
  end

  //-------------------------------------------------------------------------
  // Step 2: Instantiate Inverse ShiftRows
  //-------------------------------------------------------------------------
  inv_shiftrows u_inv_shiftrows (
    .i_valid  (i_start),         // Triggered by i_start
    .i_block  (state_reg),
    .o_valid  (o_valid_inv_shift),
    .o_block  (inv_shift_out)
  );

  //-------------------------------------------------------------------------
  // Step 3: Instantiate Inverse SubBytes
  //-------------------------------------------------------------------------
  subbytes_generic u_inv_subbytes (
    .clk      (clk),
    .rst_n    (~rst),
    .mode     (1'b1),            // Inverse mode for decryption
    .state    (inv_shift_out),
    .state_out(inv_sub_out),
    .o_valid  (o_valid_inv_sub)
  );

  //-------------------------------------------------------------------------
  // Step 4: Instantiate Inverse MixColumns (except for last round)
  //-------------------------------------------------------------------------
  inv_mixcolumns u_inv_mixcolumns (
    .i_valid  (o_valid_inv_sub),
    .i_block  (inv_sub_out),
    .o_valid  (o_valid_mix),
    .o_block  (mix_out)
  );

  //-------------------------------------------------------------------------
  // Step 5: Final AddRoundKey: XOR with the correct round key
  //-------------------------------------------------------------------------
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        reg_final <= 128'd0;
    end else if (current_state == ADD_R) begin
        reg_final <= (round_counter == 0) ? inv_sub_out ^ round_key : mix_out ^ round_key;
    end
  end

  //-------------------------------------------------------------------------
  // FSM states for one-round decryption process
  //-------------------------------------------------------------------------
  typedef enum logic [2:0] {
    IDLE,      // Waiting for start signal
    INIT,      // Initial AddRoundKey
    INV_SHIFT, // Inverse ShiftRows
    INV_SUB,   // Inverse SubBytes
    INV_MIX,   // Inverse MixColumns (except last round)
    ADD_R,     // Final AddRoundKey stage
    DONE       // Final state
  } state_t;

  state_t current_state, next_state;

  //-------------------------------------------------------------------------
  // FSM: Sequential logic controlling the one-round decryption process
  //-------------------------------------------------------------------------
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      current_state <= IDLE;
      round_counter <= 10;
      o_valid <= 0;
    end else begin
      current_state <= next_state;
      case (current_state)
        IDLE: begin
          o_valid <= 0;
        end

        INIT: begin
          round_counter <= 10;
          o_valid <= 1;
        end

        INV_SHIFT: begin
          reg_inv_shift <= inv_shift_out;
          round_counter <= round_counter - 1;
        end

        INV_SUB: begin
          reg_inv_sub <= inv_sub_out;
          round_counter <= round_counter - 1;
        end

        INV_MIX: begin
          if (round_counter > 0) begin  // Apply MixColumns for rounds > 0
            reg_add_r <= mix_out;
          end
          round_counter <= round_counter - 1;
        end

        ADD_R: begin
          if (round_counter > 0) begin
            reg_final <= reg_add_r ^ round_key;
          end else begin
            reg_final <= inv_sub_out ^ round_key;  // Last round skips MixColumns
          end
          round_counter <= round_counter - 1;
          o_valid <= 1;
        end

        DONE: begin
          o_valid <= 0;
        end

        default: ;
      endcase
    end
  end

  //-------------------------------------------------------------------------
  // FSM: Combinational next state logic
  //-------------------------------------------------------------------------
  always_comb begin
    next_state = current_state;
    case (current_state)
      IDLE:       next_state = (i_start) ? INIT : IDLE;
      INIT:       next_state = INV_SHIFT;
      INV_SHIFT:  next_state = (o_valid_inv_shift) ? INV_SUB : INV_SHIFT;
      INV_SUB:    next_state = (o_valid_inv_sub) ? (round_counter > 0 ? INV_MIX : ADD_R) : INV_SUB;
      INV_MIX:    next_state = (o_valid_mix) ? ADD_R : INV_MIX;
      ADD_R:      next_state = (round_counter == 0) ? DONE : INV_SHIFT;
      DONE:       next_state = IDLE;
      default:    next_state = IDLE;
    endcase
  end

  //-------------------------------------------------------------------------
  // Final output assignment
  //-------------------------------------------------------------------------
  assign o_state = reg_final;

endmodule




