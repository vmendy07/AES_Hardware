create_clock -period 10 [get_ports clk]
set_input_delay -clock [get_clocks clk] 2.5 [get_ports {ciphertext[*]}]
set_output_delay -clock [get_clocks clk] 2.5 [get_ports {plaintext[*]}]