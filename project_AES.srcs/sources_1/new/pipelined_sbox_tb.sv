`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.02.2025 23:43:12
// Design Name: 
// Module Name: pipelined_sbox_tb
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


module tb_pipelined_sbox;

    // Declare wires and regs
    reg clk;
    reg [31:0] in_data;
    wire [31:0] out_data;

    // Instantiate the pipelined_sbox module
    pipelined_sbox uut (
        .clk(clk),
        .in(in_data),
        .out(out_data)
    );

    // Clock generation (50 MHz clock)
    always begin
        #10 clk = ~clk; // 50 MHz clock, period = 20 ns
    end

    // Testbench initial block
    initial begin
        // Initialize signals
        clk = 0;
        in_data = 32'h01234567; // Example input value

        // Display initial values
        $display("Input: 0x%h", in_data);

        // Apply different test cases
        $display("\nRunning Test 1...");
        in_data = 32'h01234567; // Example input, change as needed
        #20; // Wait for one clock cycle
        
        $display("Output: 0x%h", out_data);

        $display("\nRunning Test 2...");
        in_data = 32'h89abcdef; // Another example input
        #20;
        
        $display("Output: 0x%h", out_data);

        $display("\nRunning Test 3...");
        in_data = 32'h00000000; // Zero input
        #20;
        
        $display("Output: 0x%h", out_data);

        $display("\nRunning Test 4...");
        in_data = 32'hffffffff; // All ones input
        #20;
        
        $display("Output: 0x%h", out_data);

        // End simulation
        $finish;
    end

endmodule

