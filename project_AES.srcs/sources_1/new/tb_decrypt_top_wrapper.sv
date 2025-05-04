`timescale 1ns / 1ps

module tb_decrypt_top_streaming_wrapper;

    parameter IO_WIDTH = 16;

    reg clk;
    reg rst;

    // Streaming input interface
    reg                  in_valid;
    reg  [IO_WIDTH-1:0]  in_ciphertext;
    reg  [IO_WIDTH-1:0]  in_key;
    wire                 in_ready;

    // Streaming output interface
    wire                 out_valid;
    wire [IO_WIDTH-1:0]  out_plaintext;
    reg                  out_ready;

    // Instantiate the wrapper
    decrypt_top_streaming_wrapper #(
        .IO_WIDTH(IO_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .in_ciphertext(in_ciphertext),
        .in_key(in_key),
        .in_ready(in_ready),
        .out_valid(out_valid),
        .out_plaintext(out_plaintext),
        .out_ready(out_ready)
    );

    // Test vectors (replace with real values for a real test)
    reg [127:0] test_ciphertext;
    reg [127:0] test_key;
    reg [127:0] expected_plaintext; // For checking output

    // Output collection
    reg [127:0] received_plaintext;
    integer out_count;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Test sequence
    initial begin
        // Example test values (replace with real test vectors)
        test_ciphertext    = 128'h3071708ffd2412229b2677ba5f1c52d2;
        test_key           = 128'h000102030405060708090a0b0c0d0e0f;
        expected_plaintext = 128'h0123456789abcdef0123456789abcdef; // Replace with actual expected

        // Initialize
        rst = 1;
        in_valid = 0;
        in_ciphertext = 0;
        in_key = 0;
        out_ready = 1;
        received_plaintext = 0;
        out_count = 0;

        #20;
        rst = 0;
        #10;

        // Stream in ciphertext and key (MSB first)
        for (int i = 0; i < 128/IO_WIDTH; i++) begin
            @(posedge clk);
            if (in_ready) begin
                in_ciphertext = test_ciphertext[127 - i*IO_WIDTH -: IO_WIDTH];
                in_key        = test_key[127 - i*IO_WIDTH -: IO_WIDTH];
                in_valid      = 1;
            end else begin
                in_valid = 0;
                i = i - 1; // Wait until ready
            end
        end
        @(posedge clk);
        in_valid = 0;
        in_ciphertext = 0;
        in_key = 0;

        // Wait for output and collect it
        out_count = 0;
        received_plaintext = 0;
        wait (out_valid); // Wait for first valid output
        while (out_count < 128/IO_WIDTH) begin
            if (out_valid) begin
                received_plaintext = (out_plaintext << (out_count*IO_WIDTH)) | received_plaintext;
                out_count = out_count + 1;
            end
            @(posedge clk);
        end

        // Display results
        $display("Input ciphertext : %h", test_ciphertext);
        $display("Input key        : %h", test_key);
        $display("Output plaintext : %h", received_plaintext);
        $display("Expected         : %h", expected_plaintext);

        if (received_plaintext === expected_plaintext)
            $display("Test PASSED!");
        else
            $display("Test FAILED!");

        #50;
        $finish;
    end

endmodule