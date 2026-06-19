`timescale 1ns / 1ps

module riscv_password_lock_top #(
    parameter MEM_FILE = "firmware/final_project.mem"
) (
    input  wire       clk,
    input  wire       btnC,
    input  wire       btnU,
    input  wire       btnD,
    input  wire [3:0] sw,
    output wire [3:0] led,
    output wire [6:0] seg,
    output wire       dp,
    output wire [3:0] an
);
    localparam MMIO_IN_ADDR  = 32'h8000_0000;
    localparam MMIO_OUT_ADDR = 32'h8000_0004;

    wire        mem_valid;
    wire        mem_instr;
    reg         mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    reg  [31:0] mem_rdata;

    wire [31:0] imem_rdata;
    wire [31:0] mmio_rdata;
    wire [3:0]  led_state;
    wire [3:0]  attempts_digit;
    wire [3:0]  display_mode;
    wire        mmio_write = mem_valid && |mem_wstrb && (mem_addr == MMIO_OUT_ADDR);

    picorv32 #(
        .ENABLE_COUNTERS(0),
        .ENABLE_REGS_16_31(1),
        .ENABLE_REGS_DUALPORT(1),
        .TWO_STAGE_SHIFT(1),
        .BARREL_SHIFTER(0),
        .COMPRESSED_ISA(0),
        .CATCH_MISALIGN(0),
        .CATCH_ILLINSN(0),
        .ENABLE_PCPI(0),
        .ENABLE_MUL(0),
        .ENABLE_DIV(0),
        .ENABLE_IRQ(0),
        .PROGADDR_RESET(32'h0000_0000),
        .STACKADDR(32'h0000_0400)
    ) cpu (
        .clk(clk),
        .resetn(~btnC),
        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata)
    );

    instruction_memory #(
        .MEM_FILE(MEM_FILE)
    ) imem (
        .addr(mem_addr),
        .rdata(imem_rdata)
    );

    mmio_controller mmio (
        .clk(clk),
        .reset(btnC),
        .sw(sw),
        .btn_confirm(btnU),
        .btn_change(btnD),
        .write_en(mmio_write),
        .addr(mem_addr),
        .wdata(mem_wdata),
        .rdata(mmio_rdata),
        .led_state(led_state),
        .attempts_digit(attempts_digit),
        .display_mode(display_mode)
    );

    always @(*) begin
        mem_ready = mem_valid;
        if (mem_addr == MMIO_IN_ADDR) begin
            mem_rdata = mmio_rdata;
        end else begin
            mem_rdata = imem_rdata;
        end
    end

    assign led = led_state;

    seven_segment_decoder sevenseg (
        .clk(clk),
        .display_mode(display_mode),
        .digit(attempts_digit),
        .seg(seg),
        .an(an),
        .dp(dp)
    );
endmodule
