`timescale 1ns / 1ps

module trng_health_tests #(
    parameter [7:0] C_RCT = 8'd30,
    parameter [10:0] C_APT_HIGH = 11'd640,
    parameter [10:0] C_APT_LOW = 11'd384
) (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire raw_bit,
    output wire alarm
);

    reg last_bit;
    reg [7:0] rct_cnt;
    reg alarm_rct;

    reg [10:0] apt_sample_cnt;
    reg [10:0] apt_ones_cnt;
    reg alarm_apt;

    wire [10:0] next_ones_cnt;

    assign next_ones_cnt = apt_ones_cnt + (raw_bit ? 11'd1 : 11'd0);
    assign alarm = alarm_rct || alarm_apt;

    always @(posedge clk) begin
        if (!rst_n) begin
            last_bit <= 1'b0;
            rct_cnt <= 8'd0;
            alarm_rct <= 1'b0;
        end else if (enable) begin
            if (rct_cnt == 8'd0) begin
                last_bit <= raw_bit;
                rct_cnt <= 8'd1;
            end else if (raw_bit == last_bit) begin
                if (rct_cnt < C_RCT) begin
                    rct_cnt <= rct_cnt + 8'd1;
                end else begin
                    alarm_rct <= 1'b1;
                end
            end else begin
                last_bit <= raw_bit;
                rct_cnt <= 8'd1;
            end
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            apt_sample_cnt <= 11'd0;
            apt_ones_cnt <= 11'd0;
            alarm_apt <= 1'b0;
        end else if (enable) begin
            if (apt_sample_cnt == 11'd1023) begin
                apt_sample_cnt <= 11'd0;
                if ((next_ones_cnt >= C_APT_HIGH) || (next_ones_cnt <= C_APT_LOW)) begin
                    alarm_apt <= 1'b1;
                end
                apt_ones_cnt <= 11'd0;
            end else begin
                apt_sample_cnt <= apt_sample_cnt + 11'd1;
                apt_ones_cnt <= next_ones_cnt;
            end
        end
    end

endmodule
