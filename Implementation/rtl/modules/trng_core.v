`timescale 1ns / 1ps
`include "trng_defs.vh"

module trng_core #(
    parameter FIFO_DEPTH = `TRNG_FIFO_DEPTH,
    parameter FIFO_ADDR_WIDTH = `TRNG_FIFO_ADDR_WIDTH,
    parameter [7:0] C_RCT = `TRNG_C_RCT,
    parameter [10:0] C_APT_HIGH = `TRNG_C_APT_HIGH,
    parameter [10:0] C_APT_LOW = `TRNG_C_APT_LOW
) (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output wire [31:0] out_data,
    output wire out_valid,
    input wire out_ready,
    output wire error
);

    wire raw_bit;
    wire corr_bit;
    wire corr_valid;
    wire alarm;

    reg [31:0] shift_reg;
    reg [4:0] bit_cnt;
    reg fifo_wr_en;
    reg [31:0] fifo_din;

    wire fifo_rd_en;
    wire [31:0] fifo_dout;
    wire fifo_full;
    wire fifo_empty;

    reg [31:0] out_data_reg;
    reg out_valid_reg;
    reg fifo_rd_en_d1;

    assign error = alarm;

    trng_entropy u_entropy (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .raw_bit(raw_bit)
    );

    trng_health_tests #(
        .C_RCT(C_RCT),
        .C_APT_HIGH(C_APT_HIGH),
        .C_APT_LOW(C_APT_LOW)
    ) u_health_tests (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .raw_bit(raw_bit),
        .alarm(alarm)
    );

    trng_corrector u_corrector (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable && !alarm),
        .raw_bit(raw_bit),
        .corr_bit(corr_bit),
        .corr_valid(corr_valid)
    );

    always @(posedge clk) begin
        if (!rst_n) begin
            shift_reg <= 32'd0;
            bit_cnt <= 5'd0;
            fifo_wr_en <= 1'b0;
            fifo_din <= 32'd0;
        end else if (enable && !alarm) begin
            fifo_wr_en <= 1'b0;
            if (corr_valid) begin
                shift_reg <= {shift_reg[30:0], corr_bit};
                bit_cnt <= bit_cnt + 5'd1;
                if (bit_cnt == 5'd31) begin
                    fifo_wr_en <= 1'b1;
                    fifo_din <= {shift_reg[30:0], corr_bit};
                    bit_cnt <= 5'd0;
                end
            end
        end else begin
            fifo_wr_en <= 1'b0;
        end
    end

    trng_fifo #(
        .WIDTH(32),
        .DEPTH(FIFO_DEPTH),
        .ADDR_WIDTH(FIFO_ADDR_WIDTH)
    ) u_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(fifo_wr_en),
        .din(fifo_din),
        .rd_en(fifo_rd_en),
        .dout(fifo_dout),
        .full(fifo_full),
        .empty(fifo_empty)
    );

    assign fifo_rd_en = (!out_valid_reg || (out_valid_reg && out_ready)) && !fifo_empty;

    always @(posedge clk) begin
        if (!rst_n) begin
            fifo_rd_en_d1 <= 1'b0;
        end else begin
            fifo_rd_en_d1 <= fifo_rd_en;
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            out_data_reg <= 32'd0;
            out_valid_reg <= 1'b0;
        end else begin
            if (fifo_rd_en_d1) begin
                out_data_reg <= fifo_dout;
                out_valid_reg <= 1'b1;
            end else if (out_valid_reg && out_ready) begin
                out_valid_reg <= 1'b0;
            end
        end
    end

    assign out_data = out_data_reg;
    assign out_valid = out_valid_reg;

endmodule
