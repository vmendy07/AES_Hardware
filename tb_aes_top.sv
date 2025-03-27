`timescale 1ps/1ps

module tb_aes_top;

  // Testbench signals
  logic         clk, rst;
  logic         i_start;
  logic [127:0] i_plaintext;
  logic [127:0] i_key;
  logic [127:0] o_ciphertext;
  logic         o_valid;
  reg [127:0] round_keys_reg;

  // Instantiate the AES top module
  aes_top uut (
    .clk         (clk),
    .rst         (rst),
    .i_start     (i_start),
    .i_plaintext (i_plaintext),
    .i_key       (i_key),
    .o_ciphertext(o_ciphertext),
    .o_valid     (o_valid)
  );

  // Clock generation: 10 ns period (half period = 5000 ps)
  initial begin
    clk = 0;
    forever #5000 clk = ~clk;
  end

  // Stimulus: assert reset then drive the AES-128 test vector.
  // Plaintext = 00112233445566778899aabbccddeeff
  // Key       = 000102030405060708090a0b0c0d0e0f
  // Expected (after initial AddRoundKey): 00102030405060708090a0b0c0d0e0f0
  // Expected final ciphertext: 69c4e0d86a7b0430d8cdb78070b4c55a
  initial begin
    rst         = 1;
    i_start     = 1'b0;
    i_plaintext = 128'h00112233445566778899aabbccddeeff;
    i_key       = 128'h000102030405060708090a0b0c0d0e0f;
    #15000;  // hold reset a little longer
    rst = 0;
    #10000;  // allow signals to settle
    $display("/// Starting encryption at time %t", $time);
    i_start = 1;
    #10000;
    i_start = 0;
  end

  //-------------------------------------------------------------------------
  // Golden functions for intermediate stage checking
  //-------------------------------------------------------------------------

  // Golden S-box lookup table (copied from the design)
  localparam logic [7:0] sbox[0:255] = '{
    8'h63,8'h7c,8'h77,8'h7b,8'hf2,8'h6b,8'h6f,8'hc5,
    8'h30,8'h01,8'h67,8'h2b,8'hfe,8'hd7,8'hab,8'h76,
    8'hca,8'h82,8'hc9,8'h7d,8'hfa,8'h59,8'h47,8'hf0,
    8'had,8'hd4,8'ha2,8'haf,8'h9c,8'ha4,8'h72,8'hc0,
    8'hb7,8'hfd,8'h93,8'h26,8'h36,8'h3f,8'hf7,8'hcc,
    8'h34,8'ha5,8'he5,8'hf1,8'h71,8'hd8,8'h31,8'h15,
    8'h04,8'hc7,8'h23,8'hc3,8'h18,8'h96,8'h05,8'h9a,
    8'h07,8'h12,8'h80,8'he2,8'heb,8'h27,8'hb2,8'h75,
    8'h09,8'h83,8'h2c,8'h1a,8'h1b,8'h6e,8'h5a,8'ha0,
    8'h52,8'h3b,8'hd6,8'hb3,8'h29,8'he3,8'h2f,8'h84,
    8'h53,8'hd1,8'h00,8'hed,8'h20,8'hfc,8'hb1,8'h5b,
    8'h6a,8'hcb,8'hbe,8'h39,8'h4a,8'h4c,8'h58,8'hcf,
    8'hd0,8'hef,8'haa,8'hfb,8'h43,8'h4d,8'h33,8'h85,
    8'h45,8'hf9,8'h02,8'h7f,8'h50,8'h3c,8'h9f,8'ha8,
    8'h51,8'ha3,8'h40,8'h8f,8'h92,8'h9d,8'h38,8'hf5,
    8'hbc,8'hb6,8'hda,8'h21,8'h10,8'hff,8'hf3,8'hd2,
    8'hcd,8'h0c,8'h13,8'hec,8'h5f,8'h97,8'h44,8'h17,
    8'hc4,8'ha7,8'h7e,8'h3d,8'h64,8'h5d,8'h19,8'h73,
    8'h60,8'h81,8'h4f,8'hdc,8'h22,8'h2a,8'h90,8'h88,
    8'h46,8'hee,8'hb8,8'h14,8'hde,8'h5e,8'h0b,8'hdb,
    8'he0,8'h32,8'h3a,8'h0a,8'h49,8'h06,8'h24,8'h5c,
    8'hc2,8'hd3,8'hac,8'h62,8'h91,8'h95,8'he4,8'h79,
    8'he7,8'hc8,8'h37,8'h6d,8'h8d,8'hd5,8'h4e,8'ha9,
    8'h6c,8'h56,8'hf4,8'hea,8'h65,8'h7a,8'hae,8'h08,
    8'hba,8'h78,8'h25,8'h2e,8'h1c,8'ha6,8'hb4,8'hc6,
    8'he8,8'hdd,8'h74,8'h1f,8'h4b,8'hbd,8'h8b,8'h8a,
    8'h70,8'h3e,8'hb5,8'h66,8'h48,8'h03,8'hf6,8'h0e,
    8'h61,8'h35,8'h57,8'hb9,8'h86,8'hc1,8'h1d,8'h9e,
    8'he1,8'hf8,8'h98,8'h11,8'h69,8'hd9,8'h8e,8'h94,
    8'h9b,8'h1e,8'h87,8'he9,8'hce,8'h55,8'h28,8'hdf,
    8'h8c,8'ha1,8'h89,8'h0d,8'hbf,8'he6,8'h42,8'h68,
    8'h41,8'h99,8'h2d,8'h0f,8'hb0,8'h54,8'hbb,8'h16
  };

  // Golden SubBytes: apply S-box on each byte of the state.
  function automatic [127:0] golden_subbytes(input [127:0] data);
    integer i;
    reg [7:0] byte_array [0:15];
    begin
      for (i = 0; i < 16; i=i+1) begin
        // Extract each byte; note the most-significant first ordering.
        byte_array[i] = sbox[data[127 - i*8 -: 8]];
      end
      golden_subbytes = { byte_array[0],  byte_array[1],  byte_array[2],  byte_array[3],
                          byte_array[4],  byte_array[5],  byte_array[6],  byte_array[7],
                          byte_array[8],  byte_array[9],  byte_array[10], byte_array[11],
                          byte_array[12], byte_array[13], byte_array[14], byte_array[15] };
    end
  endfunction

  // Golden ShiftRows: rearrange bytes according to AES specification.
  function automatic [127:0] golden_shiftrows(input [127:0] state);
    reg [7:0] b0, b1, b2, b3, b4, b5, b6, b7,
              b8, b9, b10, b11, b12, b13, b14, b15;
    begin
      b0  = state[127:120];
      b1  = state[119:112];
      b2  = state[111:104];
      b3  = state[103:96];
      b4  = state[95:88];
      b5  = state[87:80];
      b6  = state[79:72];
      b7  = state[71:64];
      b8  = state[63:56];
      b9  = state[55:48];
      b10 = state[47:40];
      b11 = state[39:32];
      b12 = state[31:24];
      b13 = state[23:16];
      b14 = state[15:8];
      b15 = state[7:0];
      // ShiftRows: row0 unchanged, row1 shift left 1, row2 shift left 2, row3 shift left 3.
      golden_shiftrows = { b0,  b5,  b10, b15,
                           b4,  b9,  b14, b3,
                           b8,  b13, b2,  b7,
                           b12, b1,  b6,  b11 };
    end
  endfunction

  // Golden helper for MixColumns.
  function automatic [7:0] golden_xtime(input [7:0] b);
    begin
      golden_xtime = (b[7]) ? ((b << 1) ^ 8'h1b) : (b << 1);
    end
  endfunction

  // Golden MixColumn for a single 32-bit column.
  function automatic [31:0] golden_mixcolumn(input [31:0] col);
    reg [7:0] a0, a1, a2, a3;
    reg [7:0] r0, r1, r2, r3;
    begin
      a0 = col[31:24];
      a1 = col[23:16];
      a2 = col[15:8];
      a3 = col[7:0];
      r0 = golden_xtime(a0) ^ (golden_xtime(a1) ^ a1) ^ a2 ^ a3;
      r1 = a0 ^ golden_xtime(a1) ^ (golden_xtime(a2) ^ a2) ^ a3;
      r2 = a0 ^ a1 ^ golden_xtime(a2) ^ (golden_xtime(a3) ^ a3);
      r3 = (golden_xtime(a0) ^ a0) ^ a1 ^ a2 ^ golden_xtime(a3);
      golden_mixcolumn = { r0, r1, r2, r3 };
    end
  endfunction

  // Golden MixColumns: apply MixColumn to each of the four columns.
  function automatic [127:0] golden_mixcolumns(input [127:0] state);
    reg [31:0] col0, col1, col2, col3;
    begin
      col0 = state[127:96];
      col1 = state[95:64];
      col2 = state[63:32];
      col3 = state[31:0];
      golden_mixcolumns = { golden_mixcolumn(col0),
                            golden_mixcolumn(col1),
                            golden_mixcolumn(col2),
                            golden_mixcolumn(col3) };
    end
  endfunction

  //-------------------------------------------------------------------------
  // Expected values (using the standard test vector)
  // For a proper AES key expansion, round key 0 should equal the original key.
  localparam [127:0] expected_rk0 = 128'h000102030405060708090a0b0c0d0e0f;
//  localparam [127:0] exp_expected_init = 128'h00102030405060708090a0b0c0d0e0f0; // plaintext XOR key

  // Variables to hold computed golden results at various stages
  reg [127:0] exp_init, exp_sub, exp_shift, exp_mix, exp_add;

  //-------------------------------------------------------------------------
  // Monitor intermediate stage results. These use hierarchical references to
  // check the internal registers of the AES core.
  //-------------------------------------------------------------------------
  initial begin
    // Wait until the core enters INIT state (AddRoundKey stage)
    wait(uut.current_state == uut.o_valid_add);
    @(posedge clk);
    #100;
    $display("At INIT stage (time %t):", $time);
    $display("  Round key 0: %h", uut.round_keys_reg[0]);
    $display("expected round key initial: %h", expected_rk0);
    exp_init = i_plaintext ^ expected_rk0;
    
    $display("expected init: %h", exp_init);
    
    if(uut.state_reg === exp_init)
      $display("PASS: INIT stage correct: %h", uut.state_reg);
    else
      $display("FAIL: INIT stage, expected: %h, got: %h", exp_init, uut.state_reg);

    $display("------Starting SubBytes------");
    // Wait for SUB_R stage (SubBytes)
    wait(uut.o_valid_sub);
    @(posedge clk);
    #100;
    exp_sub = golden_subbytes(exp_init);
    $display("At SUB_R stage (time %t):", $time);
    $display("  Expected SUB_R: %h", exp_sub);
    $display("  Actual   SUB_R: %h", uut.reg_sub);
    if(uut.reg_sub === exp_sub)
      $display("PASS: SUB_R stage correct");
    else
      $display("FAIL: SUB_R stage, expected: %h, got: %h", exp_sub, uut.reg_sub);
   
   $display("------Starting ShiftRows------");
    // Wait for SHIFT_R stage (ShiftRows)
    wait(uut.o_valid_shift);
    @(posedge clk);
    exp_shift = golden_shiftrows(exp_sub);
    $display("At SHIFT_R stage (time %t):", $time);
    $display("  Expected SHIFT_R: %h", exp_shift);
    $display("  Actual   SHIFT_R: %h", uut.shift_out);
    if(uut.shift_out === exp_shift)
      $display("PASS: SHIFT_R stage correct");
    else
      $display("FAIL: SHIFT_R stage, expected: %h, got: %h", exp_shift, uut.shift_out);

    $display("------Starting MixColumns------");
    // Wait for MIX_R stage (MixColumns)
    wait(uut.o_valid_mix);
    @(posedge clk);
    exp_mix = golden_mixcolumns(exp_shift);
    $display("At MIX_R stage (time %t):", $time);
    $display("  Expected MIX_R: %h", exp_mix);
    $display("  Actual   MIX_R: %h", uut.mix_out);
    if(uut.mix_out === exp_mix)
      $display("PASS: MIX_R stage correct");
    else
      $display("FAIL: MIX_R stage, expected: %h, got: %h", exp_mix, uut.mix_out);

    $display("------Starting AddRoundKey------");
    // Wait for ADD_R stage (AddRoundKey)
    exp_add = exp_mix ^ uut.round_keys_reg[uut.round_counter];
    wait(uut.o_valid_add);
    @(posedge clk);
   
    $display("At ADD_R stage (time %t):", $time);
    $display("  Expected ADD_R: %h", exp_add);
    $display("  Actual   ADD_R: %h", uut.state_reg);
    if(uut.state_reg === exp_add)
      $display("PASS: ADD_R stage correct");
    else
      $display("FAIL: ADD_R stage, expected: %h, got: %h", exp_add, uut.state_reg);
  end

//  //-------------------------------------------------------------------------
//  // Final ciphertext check.
//  //-------------------------------------------------------------------------
//  initial begin
//    wait(o_valid);
//    @(posedge clk);
//    #100;
//    $display("At DONE stage (time %t):", $time);
//    if(o_ciphertext === 128'h69c4e0d86a7b0430d8cdb78070b4c55a)
//      $display("PASS: Final ciphertext correct: %h", o_ciphertext);
//    else
//      $display("FAIL: Final ciphertext, expected: %h, got: %h",
//               128'h69c4e0d86a7b0430d8cdb78070b4c55a, o_ciphertext);
//    #10000;
//    $finish;
//end
endmodule