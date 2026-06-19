`timescale 1ns / 1ps

module tb_riscv_password_lock #(
    parameter MEM_FILE = "firmware/final_project.mem"
);
    reg clk = 1'b0;
    reg btnC = 1'b1;
    reg btnU = 1'b0;
    reg btnD = 1'b0;
    reg [3:0] sw = 4'h0;

    wire [3:0] led;
    wire [6:0] seg;
    wire dp;
    wire [3:0] an;

    riscv_password_lock_top #(
        .MEM_FILE(MEM_FILE)
    ) dut (
        .clk(clk),
        .btnC(btnC),
        .btnU(btnU),
        .btnD(btnD),
        .sw(sw),
        .led(led),
        .seg(seg),
        .dp(dp),
        .an(an)
    );

    always #5 clk = ~clk;

    task reset_system;
        begin
            btnC = 1'b1;
            btnU = 1'b0;
            btnD = 1'b0;
            sw = 4'h0;
            repeat (10) @(posedge clk);
            btnC = 1'b0;
            repeat (80) @(posedge clk);
        end
    endtask

    task press_change;
        input [3:0] value;
        begin
            sw = value;
            repeat (10) @(posedge clk);
            btnD = 1'b1;
            repeat (50) @(posedge clk);
            btnD = 1'b0;
            repeat (500) @(posedge clk);
        end
    endtask

    task press_confirm;
        input [3:0] value;
        begin
            sw = value;
            repeat (10) @(posedge clk);
            btnU = 1'b1;
            repeat (50) @(posedge clk);
            btnU = 1'b0;
            repeat (500) @(posedge clk);
        end
    endtask

    task expect_state;
        input [80*8:1] name;
        input [3:0] exp_led;
        input [3:0] exp_digit;
        begin
            if (led !== exp_led || dut.attempts_digit !== exp_digit) begin
                $display("FAIL %0s: led=%h digit=%h expected led=%h digit=%h",
                         name, led, dut.attempts_digit, exp_led, exp_digit);
                $finish;
            end else begin
                $display("PASS %0s: led=%h digit=%h", name, led, dut.attempts_digit);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_riscv_password_lock.vcd");
        $dumpvars(0, tb_riscv_password_lock);

        reset_system();
        expect_state("TC1 reset", 4'h0, 4'h3);

        press_confirm(4'hA);
        expect_state("TC2 correct password", 4'hF, 4'h0);
        if (dut.display_mode !== 4'h1) begin
            $display("FAIL TC2 PASS display: display_mode=%h", dut.display_mode);
            $finish;
        end else begin
            $display("PASS TC2 PASS display mode");
        end

        press_change(4'h5);
        expect_state("TC2B password changed and relocked", 4'h0, 4'h3);

        press_confirm(4'hA);
        expect_state("TC2C old password rejected", 4'h0, 4'h2);

        press_confirm(4'h5);
        expect_state("TC2D new password accepted", 4'hF, 4'h0);

        reset_system();
        press_confirm(4'h0);
        expect_state("TC3 one wrong attempt", 4'h0, 4'h2);

        reset_system();
        sw = 4'h0;
        repeat (10) @(posedge clk);
        btnU = 1'b1;
        repeat (1000) @(posedge clk);
        btnU = 1'b0;
        repeat (500) @(posedge clk);
        expect_state("TC4 long press debounce", 4'h0, 4'h2);

        press_confirm(4'h1);
        press_confirm(4'h2);
        expect_state("TC5 locked", 4'hA, 4'h0);
        press_confirm(4'hA);
        expect_state("TC5 locked ignores input", 4'hA, 4'h0);

        $display("All password-lock simulation tests passed.");
        $finish;
    end
endmodule
