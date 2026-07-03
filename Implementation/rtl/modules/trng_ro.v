`timescale 1ns / 1ps

module trng_ro #(
    parameter STAGES = 5
) (
    input wire enable,
    output wire out
);

`ifdef ASIC_SKY130
    wire [STAGES:0] rings;
    sky130_fd_sc_hd__nand2_1 u_nand ( .A(rings[STAGES]), .B(enable), .Y(rings[0]) );
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : gen_asic_stages
            sky130_fd_sc_hd__inv_1 u_inv ( .A(rings[i]), .Y(rings[i+1]) );
        end
    endgenerate
    assign out = rings[STAGES];
`else
    (* KEEP = "true", DONT_TOUCH = "true" *) wire [STAGES:0] rings;
    assign rings[0] = rings[STAGES] & enable;
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : gen_stages
            (* KEEP = "true", DONT_TOUCH = "true" *) assign rings[i+1] = ~rings[i];
        end
    endgenerate
    assign out = rings[STAGES];
`endif

endmodule
