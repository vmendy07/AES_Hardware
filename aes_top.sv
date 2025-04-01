module aes_top (
    input  logic         clk,
    input  logic         rst,        // active-high reset
    input  logic         i_start,    // start encryption
    input  logic [127:0] i_plaintext,
    input  logic [127:0] i_key,
    output logic [127:0] o_ciphertext,
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
  // Wire to collect the combinational output of key expansion
  logic [127:0] round_keys_w [0:NR];

  // Register array to latch the round keys for use during encryption
  reg [127:0] round_keys_reg [0:NR];

  aes_key_expansion #(4, NR) u_key_expansion (
      .seed_key(i_key),
      .expanded_keys(round_keys_w)
  );

  //-------------------------------------------------------------------------
  // Latch the expanded keys into registers.
  // When i_start is asserted, capture all round keys from round_keys_w into
  // round_keys_reg.  These registered values will be used throughout the
  // encryption process.
  //-------------------------------------------------------------------------
  integer j;
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      for (j = 0; j <= NR; j = j + 1) begin
        round_keys_reg[j] <= 128'd0;
      end
    end else if (i_start) begin
      for (j = 0; j <= NR; j = j + 1) begin
        round_keys_reg[j] <= round_keys_w[j];
      end
    end
  end

  //-------------------------------------------------------------------------
  // FSM states for running through all the rounds. The iterative datapath
  // uses the same submodule instances (SubBytes, ShiftRows, MixColumns)
  // and differentiates regular rounds from the final round (which omits MixColumns).
  //-------------------------------------------------------------------------
  typedef enum logic [3:0] {
    IDLE,    // wait for i_start
    INIT,    // initial AddRoundKey (round key 0)
    SUB_R,   // Regular round: SubBytes stage
    SHIFT_R, // Regular round: ShiftRows stage
    MIX_R,   // Regular round: MixColumns stage
    ADD_R,   // Regular round: AddRoundKey stage (update state & round counter)
    SUB_F,   // Final round: SubBytes stage
    SHIFT_F, // Final round: ShiftRows stage
    ADD_F,   // Final round: AddRoundKey stage (no MixColumns)
    DONE     // output result valid
  } state_t;

  state_t current_state, next_state;
  reg [3:0] round_counter;  // counts rounds (from 1 to 10)

  //-------------------------------------------------------------------------
  // Registers to hold the AES state and pipeline results.
  //-------------------------------------------------------------------------
  reg [127:0] state_reg;   // current AES state
  reg [127:0] reg_sub;     // captures output from SubBytes stage
  reg [127:0] reg_shift;   // captures output from ShiftRows stage
  reg [127:0] reg_mix;     // captures output from MixColumns stage

  // These registers drive the submodule inputs.
  reg [127:0] sub_in_reg;
  reg [127:0] shift_in_reg;
  reg [127:0] mix_in_reg;

  // Wires for submodule outputs.
  wire [127:0] sub_out;
  logic [127:0] shift_out;
  logic [127:0] mix_out;
  logic o_valid_sub;
  logic o_valid_shift;
  logic o_valid_mix, o_valid_add;
  
//    //-------------------------------------------------------------------------
//  // Instantiate the add_roundkey module (add_roundkey.sv).
//  //-------------------------------------------------------------------------
//add_roundkey (
//    .state (add_in_reg),      // 128-bit input representing the current AES state.
//    .round_key(round_key),  // 128-bit round key used to modify the state.
//    .state_out (add_out)   // 128-bit output after performing the bitwise XOR.
//);
  //-------------------------------------------------------------------------
  // Instantiate the SubBytes module (active-low reset tied to ~rst).
  //-------------------------------------------------------------------------
  subbytes_generic u_subbytes (
    .clk      (clk),
    .rst_n    (~rst),
//    .i_valid(o_valid_add),
    .mode     (1'b0),       // forward mode for encryption
    .state    (sub_in_reg),
    .state_out(sub_out), // output of subbytes
    .o_valid(o_valid_sub)
  );

  //-------------------------------------------------------------------------
  // Instantiate the ShiftRows module (shiftrows.sv).
  //-------------------------------------------------------------------------
  shiftrows u_shiftrows (
    .i_valid(o_valid_sub),
    .i_block(shift_in_reg),
    .o_valid(o_valid_shift),         // valid signal not used in this example
    .o_block(shift_out)
  );

  //-------------------------------------------------------------------------
  // Instantiate the MixColumns module (mixcolumns.sv).
  //-------------------------------------------------------------------------
  mixcolumns u_mixcolumns (
    .i_valid(o_valid_shift),
    .i_block(shift_out),
    .o_valid(o_valid_mix),
    .o_block(mix_out)
  );

  // Add a new signal for AddRoundKey valid
  logic o_valid_add;

  //-------------------------------------------------------------------------
  // FSM: Sequential logic driving the iterative AES datapath.
  // Each stage uses one clock cycle.
  //-------------------------------------------------------------------------
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      current_state <= IDLE;
      round_counter <= 0;
      state_reg     <= 128'd0;
      reg_sub       <= 128'd0;
      reg_shift     <= 128'd0;
      reg_mix       <= 128'd0;
      sub_in_reg    <= 128'd0;
      shift_in_reg  <= 128'd0;
      mix_in_reg    <= 128'd0;
      o_valid_add   <= 0;  // Initialize the AddRoundKey valid signal
    end else begin
      current_state <= next_state;
      case (current_state)
        IDLE: begin
          // Nothing to capture until i_start is asserted.
          o_valid_add <= 0;
        end

        INIT: begin
          // Initial round: perform AddRoundKey with round key 0.
          state_reg   <= i_plaintext ^ round_keys_reg[0];
          round_counter <= 1;  // Next round will use round_keys_reg[1]
          o_valid_add <= 1;  // Set valid signal for AddRoundKey
        end

        SUB_R: begin
          // Regular round: SubBytes.
          sub_in_reg <= state_reg;
          o_valid_add <= 0;
          if (o_valid_sub) begin
            reg_sub <= sub_out;
          end
        end

        SHIFT_R: begin
          // Regular round: ShiftRows.
          shift_in_reg <= reg_sub;
          if (o_valid_shift) begin
            reg_shift    <= shift_out;
          end
        end

        MIX_R: begin
          // Regular round: MixColumns.
          mix_in_reg <= reg_shift;
          reg_mix    <= mix_out; // not needed?
        end

        ADD_R: begin
          // Regular round: perform AddRoundKey with the latched key for the
          // current round.
          state_reg   <= reg_mix ^ round_keys_reg[round_counter];
          round_counter <= round_counter + 1;
          o_valid_add <= 1;  // Set valid signal for AddRoundKey
        end

        SUB_F: begin
          // Final round (round 10): SubBytes.
          sub_in_reg <= state_reg;
          o_valid_add <= 0;
          if (o_valid_sub) begin
            reg_sub <= sub_out;
          end
        end

        SHIFT_F: begin
          // Final round: ShiftRows.
          shift_in_reg <= reg_sub;
          if (o_valid_shift) begin
            reg_shift    <= shift_out;
          end
        end

        ADD_F: begin
          // Final round: AddRoundKey (no MixColumns).
          state_reg <= reg_shift ^ round_keys_reg[NR]; // round_keys_reg[10]
          o_valid_add <= 1;  // Set valid signal for AddRoundKey
        end

        DONE: begin
          // Encryption complete. The final ciphertext is in state_reg.
          o_valid_add <= 0;
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
      INIT:  next_state = SUB_R;
      SUB_R: next_state = (o_valid_sub) ? SHIFT_R : SUB_R;
      SHIFT_R: next_state = (o_valid_shift) ? MIX_R : SHIFT_R;
      MIX_R: next_state = ADD_R;
      ADD_R: next_state = (round_counter == 9) ? SUB_F : SUB_R;
      SUB_F: next_state = (o_valid_sub) ? SHIFT_F : SUB_F;
      SHIFT_F: next_state = (o_valid_shift) ? ADD_F : SHIFT_F;
      ADD_F: next_state = DONE;
      DONE:  next_state = IDLE;  // Changed to return to IDLE after DONE
      default: next_state = IDLE;
    endcase
  end

  //-------------------------------------------------------------------------
  // Final outputs.
  // The ciphertext is simply the final state value.
  // The o_valid signal is asserted when the FSM is in the DONE state.
  //-------------------------------------------------------------------------
  assign o_ciphertext = state_reg;
  assign o_valid      = (current_state == DONE);

endmodule 