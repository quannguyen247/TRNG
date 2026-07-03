`timescale 1ns / 1ps

module trng_fifo #(
    parameter WIDTH = 32,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = 4
) (
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire [WIDTH-1:0] din,
    input wire rd_en,
    output reg [WIDTH-1:0] dout,
    output wire full,
    output wire empty
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH:0] count;

    assign full = (count == DEPTH);
    assign empty = (count == 0);

    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            dout <= 0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: begin
                    mem[wr_ptr] <= din;
                    wr_ptr <= wr_ptr + 1;
                    count <= count + 1;
                end
                2'b01: begin
                    dout <= mem[rd_ptr];
                    rd_ptr <= rd_ptr + 1;
                    count <= count - 1;
                end
                2'b11: begin
                    mem[wr_ptr] <= din;
                    wr_ptr <= wr_ptr + 1;
                    dout <= mem[rd_ptr];
                    rd_ptr <= rd_ptr + 1;
                end
                default: ;
            endcase
        end
    end

endmodule
