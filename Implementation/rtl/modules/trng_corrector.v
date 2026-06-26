`timescale 1ns / 1ps

module trng_corrector (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire raw_bit,
    output reg corr_bit,
    output reg corr_valid
);

    reg pair_state;
    reg bit0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pair_state <= 1'b0;
            bit0 <= 1'b0;
            corr_bit <= 1'b0;
            corr_valid <= 1'b0;
        end else if (enable) begin
            corr_valid <= 1'b0;
            if (!pair_state) begin
                bit0 <= raw_bit;
                pair_state <= 1'b1;
            end else begin
                pair_state <= 1'b0;
                if (bit0 != raw_bit) begin
                    corr_bit <= bit0;
                    corr_valid <= 1'b1;
                end
            end
        end else begin
            corr_valid <= 1'b0;
        end
    end

endmodule
