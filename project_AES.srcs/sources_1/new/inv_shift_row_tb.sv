`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Sheffield
// Engineer: EBranners
// 
// Create Date: 30.03.2025 15:22:53
// Design Name: AES Inverse ShiftRows
// Module Name: tb_inv_shiftrows
// Project Name: AES Implementation
// Target Devices: FPGA
// Tool Versions: Xilinx Vivado 2021.2
// Description: 
//   This testbench verifies the functionality of the Inverse ShiftRows module
//   used in AES decryption. A golden model is used to compare the output of
//   the DUT against expected results.
//
// Dependencies: inv_shiftrows.sv
// 
// Revision:
//   Rev 0.1 - Initial version with golden model comparison and multiple tests
//
// Additional Comments:
//   This is a combinational testbench and does not use a clock or reset.
//
//////////////////////////////////////////////////////////////////////////////////

module tb_inv_shiftrows;

    // Testbench signals
    logic        i_valid;
    logic [127:0] i_block;
    logic        o_valid;
    logic [127:0] o_block;
    logic [127:0] rand_vector;

    // Golden model function for Inverse ShiftRows transformation
    function automatic [127:0] golden_inv_shiftrows(input [127:0] state);
        logic [7:0] b0,  b1,  b2,  b3;
        logic [7:0] b4,  b5,  b6,  b7;
        logic [7:0] b8,  b9,  b10, b11;
        logic [7:0] b12, b13, b14, b15;
        begin
            b0  = state[127:120]; b1  = state[119:112];
            b2  = state[111:104]; b3  = state[103:96];
            b4  = state[95:88];   b5  = state[87:80];
            b6  = state[79:72];   b7  = state[71:64];
            b8  = state[63:56];   b9  = state[55:48];
            b10 = state[47:40];   b11 = state[39:32];
            b12 = state[31:24];   b13 = state[23:16];
            b14 = state[15:8];    b15 = state[7:0];

            // Inverse ShiftRows rearrangement
            golden_inv_shiftrows = {
                b0,  b13, b10, b7,   // Row 0 unchanged, rows 1-3 rotated right
                b4,  b1,  b14, b11,
                b8,  b5,  b2,  b15,
                b12, b9,  b6,  b3
            };
        end
    endfunction

    // Task to run an individual test
    task run_test(input [127:0] test_vector, input [127:0] expected, input int test_num);
        begin
            $display("\n********** Test %0d **********", test_num);
            i_valid = 1;
            i_block = test_vector;
            #1; // Allow time for combinational output to propagate

            if (o_block === expected)
                $display("Test %0d PASS: Expected = %h, Received = %h",
                         test_num, expected, o_block);
            else begin
                $display("Test %0d FAIL: Expected = %h, Received = %h",
                         test_num, expected, o_block);
                $fatal;
            end

            i_valid = 0;
            #5;
        end
    endtask

    // Instantiate the Unit Under Test (UUT)
    inv_shiftrows uut (
        .i_valid(i_valid),
        .i_block(i_block),
        .o_valid(o_valid),
        .o_block(o_block)
    );

    // Main test sequence
    initial begin
        #10;

        // Test 1: Inverse of known ShiftRows result
        run_test(128'h00050A0F_04090E03_080D0207_0C01060B,
                 128'h00010203_04050607_08090A0B_0C0D0E0F, 1);

        // Test 2: All zero input
        run_test(128'h00000000000000000000000000000000,
                 128'h00000000000000000000000000000000, 2);

        // Test 3: All ones
        run_test(128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 3);

        // Test 4: Count-up pattern
        run_test(128'h00112233_10213203_20310213_30011223,
                 128'h00010203_10111213_20212223_30313233, 4);

        // Test 5: Random test with golden model
        rand_vector = { $urandom, $urandom, $urandom, $urandom };
        run_test(rand_vector, golden_inv_shiftrows(rand_vector), 5);

        $display("\n✅ All tests completed successfully.");
        #20;
        $finish;
    end

endmodule


