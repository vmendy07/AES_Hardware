//(* use_dsp48 = "yes" *) // Review for usefulness when it comes to inv_mix_column
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2025 15:46:30
// Design Name: 
// Module Name: aes_decryption_top_tb
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


module aes_decrypt_top (
    input  logic         clk,
    input  logic         rst,        // active-high reset
    input  logic         i_start,    // start decryption
    input  logic [127:0] i_ciphertext, // input ciphertext (for decryption)
    input  logic [127:0] i_key,
    output logic [127:0] o_plaintext,  // output plaintext (after decryption)
    output logic         o_valid
);

  //-------------------------------------------------------------------------
  // Parameters: For AES-128 there are 10 rounds; with an initial round key,
  // you need 11 round keys in total.
  //-------------------------------------------------------------------------
  parameter NR = 10;  // number of rounds

  //-------------------------------------------------------------------------
  // Instantiation of the key expansion module.
  // The module now outputs an array of 128-bit round keys.
  //-------------------------------------------------------------------------
  logic [127:0] round_keys_w [0:NR];

  // Register array to latch the round keys for use during decryption
  reg [127:0] round_keys [0:NR];

  aes_key_expansion #(4, NR) u_key_expansion (
      .seed_key(i_key),
      .expanded_keys(round_keys_w)
  );

  //-------------------------------------------------------------------------
  // Latch the expanded keys into registers.
  // When i_start is asserted, capture all round keys from round_keys_w into
  // round_keys_reg. These registered values will be used throughout the decryption process.
  //-------------------------------------------------------------------------
  integer j;
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      for (j = 0; j <= NR; j = j + 1) begin
        round_keys[j] <= 128'd0;
      end
    end else if (i_start) begin
      for (j = 0; j <= NR; j = j + 1) begin
        round_keys[j] <= round_keys_w[j];
      end
    end
  end

  //-------------------------------------------------------------------------
  // FSM states for running through all the rounds. The iterative datapath
  // uses the same submodule instances (InvSubBytes, InvShiftRows, InvMixColumns)
  // and differentiates regular rounds from the final round (which omits MixColumns).
  //-------------------------------------------------------------------------
  typedef enum logic [3:0] {
    IDLE,    // wait for i_start
    INIT,    // initial AddRoundKey (round key 0)
    INV_SUB_R,   // Regular round: InvSubBytes stage
    INV_SHIFT_R, // Regular round: InvShiftRows stage
    INV_MIX_R,   // Regular round: InvMixColumns stage
    ADD_R,   // Regular round: AddRoundKey stage (update state & round counter)
    INV_SUB_F,   // Final round: InvSubBytes stage
    INV_SHIFT_F, // Final round: InvShiftRows stage
    ADD_F,   // Final round: AddRoundKey stage (no MixColumns)
    DONE     // output result valid
  } state_t;

  state_t current_state, next_state;
  reg [3:0] round_counter;  // counts rounds (from 1 to 10)

  //-------------------------------------------------------------------------
  // Registers to hold the AES state and pipeline results.
  //-------------------------------------------------------------------------
  reg [127:0] state_reg;   // current AES state
  reg [127:0] reg_sub;     // captures output from InvSubBytes stage
  reg [127:0] reg_shift;   // captures output from InvShiftRows stage
  reg [127:0] reg_mix;     // captures output from InvMixColumns stage
  reg [127:0] reg_add_r;     // captures output from InvMixColumns stage

  // These registers drive the submodule inputs.
  reg [127:0] sub_in_reg;
  reg [127:0] shift_in_reg;
  reg [127:0] mix_in_reg;
  reg [127:0] add_in_reg;  // for add_roundkey
  
    //-------------------------------------------------------------------------
  // Dedicated Valid Handshake Signals for each stage.
  //-------------------------------------------------------------------------
  logic inv_shift_valid, inv_sub_valid, inv_mix_valid, add_valid;
  // (We use the FSM's computed result for AddRoundKey, so no separate valid is needed)

  // Wires for submodule outputs.
  wire [127:0] inv_sub_out;
  logic [127:0] inv_shift_out;
  logic [127:0] inv_mix_out;
  wire [127:0] add_out;
  logic o_valid_inv_sub;
  logic o_valid_inv_shift;
  logic o_valid_inv_mix;
  logic o_valid_add;
   
  
  //------------------------------------------------------------------------- 
  // Instantiate the InvShiftRows module (shiftrows.sv).
  //------------------------------------------------------------------------- 
  inv_shiftrows u_invshiftrows (
    .i_valid(inv_shift_valid),
    .i_block(shift_in_reg),
    .o_valid(o_valid_shift),         // valid signal not used in this example
    .o_block(inv_shift_out)
  );
  
  //------------------------------------------------------------------------- 
  // Instantiate the InvSubBytes module (active-low reset tied to ~rst).
  //------------------------------------------------------------------------- 
  subbytes_generic u_invsubbytes (
    .clk      (clk),
    .rst_n    (~rst),
    .mode     (1'b1),       // reverse mode for decryption
    .state    (sub_in_reg),
    .state_out(inv_sub_out), // output of InvSubBytes
    .o_valid(o_valid_sub)
  );

  //------------------------------------------------------------------------- 
  // Instantiate the AddRoundKey module (addroundkey.sv).
  //------------------------------------------------------------------------- 
    add_roundkey add_roundkey_inst (
        .state       (add_in_reg),       // 128-bit input state
        .round_key   (round_keys[round_counter]),  
        .state_out   (add_out),
        .i_valid     (add_valid), // Handshake input
        .o_valid     (o_valid_add) // Output valid signal
    );
  //------------------------------------------------------------------------- 
  // Instantiate the InvMixColumns module (mixcolumns.sv).
  //------------------------------------------------------------------------- 
  inv_mixcolumns u_invmixcolumns (
    .i_valid(inv_mix_valid),
    .i_block(mix_in_reg),
    .o_valid(o_valid_mix),
    .o_block(inv_mix_out)
  );
  
/*  //-------------------------------------------------------------------------
  // Generate a round completion flag.
  // For a regular round, we define "round complete" when INV_MIX_R finishes.
  // For the final round, when ADD_F finishes.
  // We'll output a one-cycle pulse on o_round_valid.
  //-------------------------------------------------------------------------
  reg o_round_valid_reg;
  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      o_round_valid_reg <= 0;
    else begin
      // For regular rounds, when transitioning out of INV_MIX_R.
      if (current_state == INV_MIX_R && o_valid_mix)
        o_round_valid_reg <= 1;
      else if (current_state == ADD_F && o_valid_add)
        o_round_valid_reg <= 1;
      else
        o_round_valid_reg <= 0;
    end
  end
  assign o_round_valid = o_round_valid_reg;  */

    //------------------------------------------------------------------------- 
    // FSM: Sequential logic driving the iterative AES datapath.
    // Each stage uses one clock cycle.
    //------------------------------------------------------------------------- 
    always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
        current_state <= IDLE;
        round_counter <= NR; // Start from round 10
        state_reg     <= 128'd0;
        reg_sub       <= 128'd0;
        reg_shift     <= 128'd0;
        reg_mix       <= 128'd0;
        reg_add_r     <= 128'd0;
        sub_in_reg    <= 128'd0;
        shift_in_reg  <= 128'd0;
        mix_in_reg    <= 128'd0;
        add_in_reg    <= 128'd0;
        inv_shift_valid   <= 0;
        inv_sub_valid     <= 0;
        inv_mix_valid     <= 0;
        add_valid   <= 0;
      end else begin
        current_state <= next_state;
        case (current_state)
          IDLE: begin
            // Nothing to capture until i_start is asserted.
            inv_shift_valid <= 0;
            inv_sub_valid   <= 0;
            inv_mix_valid   <= 0;
            add_valid   <= 0;
          end
    
          INIT: begin
            // Initial round: perform AddRoundKey with round key 10 (for decryption).
            state_reg <= i_ciphertext ^ round_keys[NR]; // XOR with last round key
            round_counter <= NR - 1;  // Next round will use round_keys_reg[9]
            //o_valid_add <= 1;  // Set valid signal for AddRoundKey
          end
    
        INV_SHIFT_R: begin
          // Prepare for Inverse ShiftRows.
          shift_in_reg <= state_reg;
          inv_shift_valid <= 1;  // Assert valid for shift stage.
          if (o_valid_shift) begin
            reg_shift <= inv_shift_out;
            inv_shift_valid <= 0; // Once latched, deassert.
          end
        end
    
        INV_SUB_R: begin
          // Prepare for Inverse SubBytes.
          sub_in_reg <= reg_shift;
          inv_sub_valid <= 1;
          if (o_valid_sub) begin
            reg_sub <= inv_sub_out;
            inv_sub_valid <= 0;
          end
        end
          
        ADD_R: begin
            add_in_reg <= reg_sub;  
            add_valid <= 1;  // Assert valid signal to AddRoundKey
            //$display("add_valid: %b, round_counter: %d", add_valid, round_counter); // Debugging
            if (o_valid_add) begin
                reg_add_r <= add_out; // Capture the output once valid
                add_valid <= 0; // Deassert valid once captured
                //$display("add_out captured: %h", add_out); // Debugging
                //round_counter <= round_counter - 1;
            end
        end

          
        INV_MIX_R: begin
          mix_in_reg <= reg_add_r;
          //$display("mix_inReg  : %h", mix_in_reg);
          //$display("reg_add-r  : %h", reg_add_r);
          inv_mix_valid <= 1;
          if (o_valid_mix) begin
            reg_mix <= inv_mix_out;
            //$display("regmix  : %h", reg_mix);
            //$display("inv-mix-out  : %h", inv_mix_out);
            inv_mix_valid <= 0; // Explicitly deassert
            state_reg <= inv_mix_out; // **Fix: update state_reg for next round**
            round_counter <= round_counter - 1;
          end
          //$display("MixColumns o_valid_mix: %b at round %d", o_valid_mix, round_counter);
        end

        INV_SHIFT_F: begin
          // Final round: Inverse ShiftRows.
          shift_in_reg <= state_reg;
          inv_shift_valid <= 1;
          if (o_valid_shift) begin
            reg_shift <= inv_shift_out;
            inv_shift_valid <= 0;
          end
        end

        INV_SUB_F: begin
          // Final round: Inverse SubBytes.
          sub_in_reg <= reg_shift;
          inv_sub_valid <= 1;
          if (o_valid_sub) begin
            reg_sub <= inv_sub_out;
            inv_sub_valid <= 0;
          end
        end
    
          ADD_F: begin
            // Final round: AddRoundKey (no InvMixColumns)
                        add_in_reg <= reg_sub;  
            add_valid <= 1;  // Assert valid signal to AddRoundKey
            //$display("add_valid: %b, round_counter: %d", add_valid, round_counter); // Debugging
            if (o_valid_add) begin
                reg_add_r <= add_out; // Capture the output once valid
                add_valid <= 0; // Deassert valid once captured
                //$display("add_out captured: %h", add_out); // Debugging
                round_counter <= round_counter - 1;
            end
          end
    
          DONE: begin
            // Decryption complete. The final plaintext is in state_reg.
          end
    
          default: ;
        endcase
      end
    end
    
    //------------------------------------------------------------------------- 
    // FSM: Combinational next state logic.
    //------------------------------------------------------------------------- 
    always_comb begin
      next_state = current_state;
      case (current_state)
        IDLE:  next_state = (i_start) ? INIT : IDLE;
        INIT:  next_state = INV_SHIFT_R;
        INV_SHIFT_R: next_state = (o_valid_shift) ? INV_SUB_R : INV_SHIFT_R;
        INV_SUB_R: next_state = (o_valid_sub) ? ADD_R : INV_SUB_R;
        ADD_R: next_state = (o_valid_add) ? 
                     ((round_counter > 0) ? INV_MIX_R : INV_SHIFT_F) : ADD_R;
        INV_MIX_R: next_state = (o_valid_mix) ? INV_SHIFT_R : INV_MIX_R;
        
        
        INV_SHIFT_F: next_state = (o_valid_shift) ? INV_SUB_F : INV_SHIFT_F;
        INV_SUB_F: next_state = (o_valid_sub) ? ADD_F : INV_SUB_F;
        ADD_F: next_state = (o_valid_add) ? DONE : ADD_F;
        DONE:  next_state = IDLE;
        default: next_state = IDLE;
      endcase
    end
    
    //------------------------------------------------------------------------- 
    // Final outputs.
    // The plaintext is simply the final state value.
    // The o_valid signal is asserted when the FSM is in the DONE state.
    //------------------------------------------------------------------------- 
    assign o_plaintext = state_reg;
    assign o_valid = (current_state == DONE);

endmodule


