`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2025 15:22:53
// Design Name: 
// Module Name: inv_shift_row_tb
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


module tb_inv_shiftrows;

    // Testbench signals
    logic        clk;
    logic        rst;
    logic        i_valid;
    logic [127:0] i_block;
    logic        o_valid;
    logic [127:0] o_block;
    logic [127:0] rand_vector;

/*    // Clock generation: 10 time unit period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset generation: Assert reset initially, then deassert
    initial begin
        rst     = 1;
        i_valid = 0;
        i_block = 128'd0;
        #12;
        rst = 0;
    end*/

    // Golden model function for Inverse ShiftRows transformation.
    function automatic [127:0] golden_inv_shiftrows(input [127:0] state);
        logic [7:0] b0,  b1,  b2,  b3;
        logic [7:0] b4,  b5,  b6,  b7;
        logic [7:0] b8,  b9,  b10, b11;
        logic [7:0] b12, b13, b14, b15;
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

           // According to Inverse ShiftRows mapping:
           // Column 0: { b0, b13, b10, b7 }
           // Column 1: { b4, b1, b14, b11 }
           // Column 2: { b8, b5, b2, b15 }
           // Column 3: { b12, b9, b6, b3 }
           golden_inv_shiftrows = { b0, b13, b10, b7,
                                    b4, b1,  b14, b11,
                                    b8, b5,  b2,  b15,
                                    b12, b9,  b6,  b3 };
        end
    endfunction

    // Task to run an individual test.
    task run_test(input [127:0] test_vector, input [127:0] expected, input int test_num);
        begin
            $display("\n********** Test %0d **********", test_num);
            i_valid = 1;
            i_block = test_vector;
            #1; // Wait for combinational logic to settle
    
            if (o_block === expected)
                $display("Test %0d PASS: Expected = %h, Received = %h",
                         test_num, expected, o_block);
            else begin
                $display("Test %0d FAILED: Expected = %h, Received = %h",
                         test_num, expected, o_block);
                $fatal;
            end
            
            i_valid = 0; // Reset valid after checking output
    
            // Wait a small delay before the next test
            #5;
        end
    endtask

    // Instantiate the inverse shiftrows module under test (UUT)
    inv_shiftrows uut (
        .i_valid(i_valid),
        .i_block(i_block),
        .o_valid(o_valid),
        .o_block(o_block)
    );

    // Test sequence using multiple test vectors.
    initial begin
        // Wait for reset to be deasserted and a clock edge to start.
        #10;

        // Test 1: Given test vector from the specification.
        // Input state (after normal ShiftRows applied):
        //   00 05 0A 0F  04 09 0E 03  08 0D 02 07  0C 01 06 0B
        // Expected Inverse ShiftRows output (original matrix before ShiftRows):
        //   00 01 02 03  04 05 06 07  08 09 0A 0B  0C 0D 0E 0F
        run_test(128'h00050A0F_04090E03_080D0207_0C01060B,
                 128'h00010203_04050607_08090A0B_0C0D0E0F, 1);

        // Test 2: All zeros should remain all zeros.
        run_test(128'h00000000000000000000000000000000,
                 128'h00000000000000000000000000000000, 2);

        // Test 3: All ones (0xFF) should remain unchanged since every byte is identical.
        run_test(128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 3);

        // Test 4: A count-up pattern.
        // After applying ShiftRows, we reverse it back to get the original.
        run_test(128'h00112233_10213203_20310213_30011223,
                 128'h00010203_10111213_20212223_30313233, 4);

        // Test 5: Random test.
        rand_vector = { $urandom, $urandom, $urandom, $urandom };
        run_test(rand_vector, golden_inv_shiftrows(rand_vector), 5);

        $display("\nAll tests completed successfully.");
        #20;
        $finish;
    end

endmodule

