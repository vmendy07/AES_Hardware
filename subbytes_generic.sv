`timescale 1ns / 1ps

module subbytes_generic (
    input  logic         mode,     // Mode select: 0 for forward S-box, 1 for inverse S-box
    input  logic [127:0] state,    // 128-bit input state (16 bytes) to be processed
    output logic [127:0] state_out // 128-bit output after applying the SubBytes substitution
);

  // Instantiate Sbox modules for each byte of the state
  Sbox sbox0 (.a(state[127:120]), .mode(mode), .b(state_out[127:120]));
  Sbox sbox1 (.a(state[119:112]), .mode(mode), .b(state_out[119:112]));
  Sbox sbox2 (.a(state[111:104]), .mode(mode), .b(state_out[111:104]));
  Sbox sbox3 (.a(state[103:96]),  .mode(mode), .b(state_out[103:96]));
  Sbox sbox4 (.a(state[95:88]),   .mode(mode), .b(state_out[95:88]));
  Sbox sbox5 (.a(state[87:80]),   .mode(mode), .b(state_out[87:80]));
  Sbox sbox6 (.a(state[79:72]),   .mode(mode), .b(state_out[79:72]));
  Sbox sbox7 (.a(state[71:64]),   .mode(mode), .b(state_out[71:64]));
  Sbox sbox8 (.a(state[63:56]),   .mode(mode), .b(state_out[63:56]));
  Sbox sbox9 (.a(state[55:48]),   .mode(mode), .b(state_out[55:48]));
  Sbox sbox10(.a(state[47:40]),   .mode(mode), .b(state_out[47:40]));
  Sbox sbox11(.a(state[39:32]),   .mode(mode), .b(state_out[39:32]));
  Sbox sbox12(.a(state[31:24]),   .mode(mode), .b(state_out[31:24]));
  Sbox sbox13(.a(state[23:16]),   .mode(mode), .b(state_out[23:16]));
  Sbox sbox14(.a(state[15:8]),    .mode(mode), .b(state_out[15:8]));
  Sbox sbox15(.a(state[7:0]),     .mode(mode), .b(state_out[7:0]));

endmodule