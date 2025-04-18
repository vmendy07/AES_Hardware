`timescale 1ns/1ps
module tb_shiftrows;

    // Testbench signals
    logic        clk;
    logic        rst;
    logic [127:0] i_block;
    logic [127:0] o_block;
    logic [127:0] rand_vector;

    // Clock generation: 10 time unit period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset generation: Assert reset initially, then deassert
    initial begin
        rst     = 1;
        i_block = 128'd0;
        #12;
        rst = 0;
    end

    // Golden model function for ShiftRows transformation.
    function automatic [127:0] golden_shiftrows(input [127:0] state);
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
           // According to ShiftRows mapping:
           // Column 0: { b0, b5, b10, b15 }
           // Column 1: { b4, b9, b14, b3 }
           // Column 2: { b8, b13, b2, b7 }
           // Column 3: { b12, b1, b6, b11 }
           golden_shiftrows = { b0, b5, b10, b15,
                                b4, b9, b14, b3,
                                b8, b13, b2, b7,
                                b12, b1, b6, b11 };
        end
    endfunction

    // Task to run an individual test.
    // It applies the test vector and checks the output.
    task run_test(input [127:0] test_vector, input [127:0] expected, input int test_num);
      begin
        @(posedge clk);
        i_block = test_vector;

        // Check the output immediately after applying the input
        #1; // Short delay to allow the combinational logic to settle
        if (o_block === expected)
           $display("Test %0d PASS: Input = %h, Expected = %h, Received = %h",
                    test_num, test_vector, expected, o_block);
        else begin
           $display("Test %0d FAILED: Input = %h, Expected = %h, Received = %h",
                    test_num, test_vector, expected, o_block);
           $fatal;
        end
      end
    endtask

    // Instantiate the shiftrows module under test (UUT)
    shiftrows uut (
        .i_block(i_block),
        .o_block(o_block)
    );

    // Test sequence using multiple test vectors.
    initial begin
        // Wait for reset to be deasserted and a clock edge to start.
        @(negedge rst);
        @(posedge clk);

        // Test 1: Given test vector from the specification.
        run_test(128'h00010203_10111213_20212223_30313233,
                 128'h00112233_10213203_20310213_30011223, 1);

        // Test 2: All zeros should remain all zeros.
        run_test(128'h00000000000000000000000000000000,
                 128'h00000000000000000000000000000000, 2);

        // Test 3: All ones (0xFF) should remain unchanged since every byte is identical.
        run_test(128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 3);

        // Test 4: Count-up pattern from 0x00 to 0x0F.
        run_test(128'h00010203_04050607_08090A0B_0C0D0E0F,
                 128'h00050A0F_04090E03_080D0207_0C01060B, 4);

        // Test 5: Random test.
        rand_vector = { $urandom, $urandom, $urandom, $urandom };
        run_test(rand_vector, golden_shiftrows(rand_vector), 5);

        $display("\nAll tests completed successfully.");
        #20;
        $finish;
    end

endmodule