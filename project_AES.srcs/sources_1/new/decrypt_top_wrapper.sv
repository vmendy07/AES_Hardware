`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.05.2025 04:23:06
// Design Name: 
// Module Name: decrypt_top_wrapper
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

module decrypt_top_streaming_wrapper #(
    parameter IO_WIDTH = 16  // Set to 16 or 32 as needed
) (
    input  wire                  clk,
    input  wire                  rst,

    // Streaming input interface
    input  wire                  in_valid,
    input  wire [IO_WIDTH-1:0]   in_ciphertext,
    input  wire [IO_WIDTH-1:0]   in_key,
    output reg                   in_ready,

    // Streaming output interface
    output reg                   out_valid,
    output reg  [IO_WIDTH-1:0]   out_plaintext,
    input  wire                  out_ready
);

    // Internal registers to collect 128 bits
    reg [127:0] ciphertext_reg;
    reg [127:0] key_reg;
    reg [3:0]   in_count;  // 128/16 = 8, needs 4 bits
    reg         collecting;

    // Output streaming
    reg [127:0] plaintext_reg;
    reg [3:0]   out_count;
    reg         output_active;

    // Connect to decrypt_top
    wire [127:0] plaintext_wire;
    wire         data_valid_wire;
    reg          input_valid_reg;

    decrypt_top uut (
        .clk(clk),
        .rst(rst),
        .input_valid(input_valid_reg),
        .ciphertext(ciphertext_reg),
        .key(key_reg),
        .plaintext(plaintext_wire),
        .data_valid(data_valid_wire)
    );

    // Input collection logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ciphertext_reg   <= 0;
            key_reg          <= 0;
            in_count         <= 0;
            input_valid_reg  <= 0;
            collecting       <= 1;
            in_ready         <= 1;
        end else begin
            input_valid_reg <= 0;
            if (collecting && in_valid && in_ready) begin
                // Shift in new data (MSB first)
                ciphertext_reg <= {ciphertext_reg[127-IO_WIDTH:0], in_ciphertext};
                key_reg        <= {key_reg[127-IO_WIDTH:0], in_key};
                in_count       <= in_count + 1;
                if (in_count == (128/IO_WIDTH - 1)) begin
                    collecting      <= 0;
                    input_valid_reg <= 1;
                    in_count        <= 0;
                    in_ready        <= 0; // Wait for decrypt_top to accept
                end
            end else if (data_valid_wire) begin
                collecting <= 1;
                in_ready   <= 1; // Ready for next block after output starts
            end
        end
    end

    // Output streaming logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            plaintext_reg  <= 0;
            out_count      <= 0;
            out_valid      <= 0;
            out_plaintext  <= 0;
            output_active  <= 0;
        end else begin
            out_valid <= 0;
            if (data_valid_wire) begin
                plaintext_reg <= plaintext_wire;
                out_count     <= 0;
                output_active <= 1;
            end
            if (output_active && out_ready) begin
                out_plaintext <= plaintext_reg[IO_WIDTH-1:0];
                out_valid     <= 1;
                plaintext_reg <= plaintext_reg >> IO_WIDTH;
                out_count     <= out_count + 1;
                if (out_count == (128/IO_WIDTH - 1)) begin
                    output_active <= 0;
                end
            end
        end
    end

endmodule