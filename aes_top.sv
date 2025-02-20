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
  // Key Expansion: Generate the expanded key schedule.
  // The aes_key_schedule module (from your file aes_key_expansion.v) produces
  // a 1408-bit bus (11 round keys × 128 bits).
  //-------------------------------------------------------------------------
  wire [0:(128*(NR+1))-1] expanded_keys;
  aes_key_schedule #(4, NR) u_key_schedule (
      .seed_key(i_key),
      .expanded_keys(expanded_keys)
  );

  //-------------------------------------------------------------------------
  // Extract each 128-bit round key from the expanded key bus.
  // The display testbench in aes_key_expansion_tb.v extracts the keys in this
  // order. For round 0, the key is in bits [1407:1280], for round 1 [1279:1152], etc.
  //-------------------------------------------------------------------------
  wire [127:0] round_keys [0:NR];  // round_keys[0] ... round_keys[10]
  genvar i;
  generate
    for (i = 0; i < (NR+1); i = i + 1) begin: round_key_extract
      assign round_keys[i] = expanded_keys[1407 - i*128 -: 128];
    end
  endgenerate

  //-------------------------------------------------------------------------
  // FSM states for running through all the rounds. The iterative datapath
  // uses the same submodule instances (SubBytes, ShiftRows, MixColumns) and
  // differentiates regular rounds from the final round (which omits MixColumns).
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
  wire [127:0] shift_out;
  wire [127:0] mix_out;

  //-------------------------------------------------------------------------
  // Instantiate the SubBytes module (subbytes_generic.v).
  // It uses active-low reset so we tie rst_n to ~rst.
  // For encryption we use mode = 0.
  //-------------------------------------------------------------------------
  subbytes_generic u_subbytes (
    .clk      (clk),
    .rst_n    (~rst),
    .mode     (1'b0),       // forward mode for encryption
    .state    (sub_in_reg),
    .state_out(sub_out)
  );

  //-------------------------------------------------------------------------
  // Instantiate the ShiftRows module (shiftrows.sv).
  //-------------------------------------------------------------------------
  shiftrows u_shiftrows (
    .clk    (clk),
    .rst    (rst),
    .i_valid(1'b1),
    .i_block(shift_in_reg),
    .o_valid(),         // valid signal not used in this example
    .o_block(shift_out)
  );

  //-------------------------------------------------------------------------
  // Instantiate the MixColumns module (mixcolumns.sv).
  //-------------------------------------------------------------------------
  mixcolumns u_mixcolumns (
    .clk    (clk),
    .rst    (rst),
    .i_valid(1'b1),
    .i_block(mix_in_reg),
    .o_valid(),
    .o_block(mix_out)
  );

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
    end else begin
      current_state <= next_state;
      case (current_state)
        IDLE: begin
          // Nothing to capture until i_start is asserted.
        end

        INIT: begin
          // Initial round: perform AddRoundKey with round key 0.
          state_reg   <= i_plaintext ^ round_keys[0];
          round_counter <= 1;  // Next round will be round key 1
        end

        SUB_R: begin
          // Regular round: SubBytes.
          sub_in_reg <= state_reg;
          reg_sub    <= sub_out;
        end

        SHIFT_R: begin
          // Regular round: ShiftRows.
          shift_in_reg <= reg_sub;
          reg_shift    <= shift_out;
        end

        MIX_R: begin
          // Regular round: MixColumns.
          mix_in_reg <= reg_shift;
          reg_mix    <= mix_out;
        end

        ADD_R: begin
          // Regular round: AddRoundKey.
          state_reg   <= reg_mix ^ round_keys[round_counter];
          round_counter <= round_counter + 1;
        end

        SUB_F: begin
          // Final round (round 10): SubBytes.
          sub_in_reg <= state_reg;
          reg_sub    <= sub_out;
        end

        SHIFT_F: begin
          // Final round: ShiftRows.
          shift_in_reg <= reg_sub;
          reg_shift    <= shift_out;
        end

        ADD_F: begin
          // Final round: AddRoundKey (no MixColumns).
          state_reg <= reg_shift ^ round_keys[NR]; // round_keys[10]
        end

        DONE: begin
          // Encryption complete. The final ciphertext is in state_reg.
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
      SUB_R: next_state = SHIFT_R;
      SHIFT_R: next_state = MIX_R;
      MIX_R: next_state = ADD_R;
      ADD_R: next_state = (round_counter == 10) ? SUB_F : SUB_R;
      SUB_F: next_state = SHIFT_F;
      SHIFT_F: next_state = ADD_F;
      ADD_F: next_state = DONE;
      DONE:  next_state = DONE;
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