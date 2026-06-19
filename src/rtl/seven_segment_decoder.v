`timescale 1ns / 1ps

module seven_segment_decoder (
    input  wire       clk,
    input  wire [3:0] display_mode,
    input  wire [3:0] digit,
    output reg  [6:0] seg,
    output reg  [3:0] an,
    output wire       dp
);
    reg [15:0] scan_counter = 16'd0;
    wire [1:0] scan_sel = scan_counter[15:14];
    reg [4:0] symbol;

    localparam MODE_DIGIT = 4'h0;
    localparam MODE_PASS  = 4'h1;
    localparam [4:0] SYM_A     = 5'h0A;
    localparam [4:0] SYM_P     = 5'h10;
    localparam [4:0] SYM_S     = 5'h11;
    localparam [4:0] SYM_BLANK = 5'h1F;

    assign dp = 1'b1;

    always @(posedge clk) begin
        scan_counter <= scan_counter + 16'd1;
    end

    always @(*) begin
        if (display_mode == MODE_PASS) begin
            case (scan_sel)
                2'd0: begin an = 4'b1110; symbol = SYM_S; end
                2'd1: begin an = 4'b1101; symbol = SYM_S; end
                2'd2: begin an = 4'b1011; symbol = SYM_A; end
                2'd3: begin an = 4'b0111; symbol = SYM_P; end
                default: begin an = 4'b1111; symbol = SYM_BLANK; end
            endcase
        end else begin
            an = 4'b1110;
            symbol = {1'b0, digit};
        end
    end

    always @(*) begin
        case (symbol)
            5'h00: seg = 7'b1000000;
            5'h01: seg = 7'b1111001;
            5'h02: seg = 7'b0100100;
            5'h03: seg = 7'b0110000;
            5'h04: seg = 7'b0011001;
            5'h05: seg = 7'b0010010;
            5'h06: seg = 7'b0000010;
            5'h07: seg = 7'b1111000;
            5'h08: seg = 7'b0000000;
            5'h09: seg = 7'b0010000;
            SYM_A: seg = 7'b0001000;
            SYM_P: seg = 7'b0001100;
            SYM_S: seg = 7'b0010010;
            5'h0C: seg = 7'b1000110;
            5'h0D: seg = 7'b0100001;
            5'h0E: seg = 7'b0000110;
            SYM_BLANK: seg = 7'b1111111;
            default: seg = 7'b1111111;
        endcase
    end
endmodule
