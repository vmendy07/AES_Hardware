module add_roundkey (
    input  logic [127:0] state,      // The current state of the AES block
    input  logic [127:0] round_key,  // The round key (from your key expansion)
    output logic [127:0] state_out   // The new state after the round key is added
);

  // Perform the AddRoundKey operation via bitwise XOR
  assign state_out = state ^ round_key;

endmodule 