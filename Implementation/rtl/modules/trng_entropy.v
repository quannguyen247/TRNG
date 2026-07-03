`timescale 1ns / 1ps
`include "trng_defs.vh"

module trng_entropy (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output wire raw_bit
);

`ifndef SIMULATION
    wire ro3_out;
    wire ro5_out;
    wire ro7_out;
    wire ro11_out;
    wire combined_ro;

    trng_ro #( .STAGES(`TRNG_RO3_STAGES) ) u_ro3 ( .enable(enable), .out(ro3_out) );
    trng_ro #( .STAGES(`TRNG_RO5_STAGES) ) u_ro5 ( .enable(enable), .out(ro5_out) );
    trng_ro #( .STAGES(`TRNG_RO7_STAGES) ) u_ro7 ( .enable(enable), .out(ro7_out) );
    trng_ro #( .STAGES(`TRNG_RO11_STAGES) ) u_ro11 ( .enable(enable), .out(ro11_out) );

    assign combined_ro = ro3_out ^ ro5_out ^ ro7_out ^ ro11_out;

    reg sync_reg0;
    reg sync_reg1;

    always @(posedge clk) begin
        if (!rst_n) begin
            sync_reg0 <= 1'b0;
            sync_reg1 <= 1'b0;
        end else begin
            sync_reg0 <= combined_ro;
            sync_reg1 <= sync_reg0;
        end
    end
`endif

`ifdef SIMULATION
    reg sim_bit;
    always @(posedge clk) begin
        if (!rst_n) begin
            sim_bit <= 1'b0;
        end else begin
            sim_bit <= $random;
        end
    end
    assign raw_bit = sim_bit;
`else
    assign raw_bit = sync_reg1;
`endif

endmodule
