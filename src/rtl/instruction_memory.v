`timescale 1ns / 1ps

module instruction_memory #(
    parameter MEM_WORDS = 256,
    parameter MEM_FILE = "firmware/final_project.mem"
) (
    input  wire [31:0] addr,
    output wire [31:0] rdata
);
    reg [31:0] mem [0:MEM_WORDS-1];
    wire [31:0] word_addr = addr[31:2];

    initial begin
        $readmemh(MEM_FILE, mem);
    end

    assign rdata = (word_addr < MEM_WORDS) ? mem[word_addr] : 32'h00000013;
endmodule
