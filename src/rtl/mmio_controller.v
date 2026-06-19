`timescale 1ns / 1ps

module mmio_controller (
    input  wire        clk,
    input  wire        reset,
    input  wire [3:0]  sw,
    input  wire        btn_confirm,
    input  wire        btn_change,
    input  wire        write_en,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output wire [31:0] rdata,
    output reg  [3:0]  led_state,
    output reg  [3:0]  attempts_digit,
    output reg  [3:0]  display_mode
);
    localparam MMIO_IN_ADDR  = 32'h8000_0000;
    localparam MMIO_OUT_ADDR = 32'h8000_0004;

    assign rdata = (addr == MMIO_IN_ADDR) ? {26'b0, btn_change, sw, btn_confirm} : 32'h0000_0000;

    always @(posedge clk) begin
        if (reset) begin
            led_state <= 4'h0;
            attempts_digit <= 4'h3;
            display_mode <= 4'h0;
        end else if (write_en && addr == MMIO_OUT_ADDR) begin
            led_state <= wdata[3:0];
            attempts_digit <= wdata[7:4];
            display_mode <= wdata[11:8];
        end
    end
endmodule
