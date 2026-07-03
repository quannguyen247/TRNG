`timescale 1ns / 1ps
`define SIMULATION

module tb_trng;

    localparam integer CLK_PERIOD_NS = 10;
    localparam integer NUM_SAMPLES = 1000;

    logic clk;
    logic rst_n;
    logic enable;
    logic [31:0] out_data;
    logic out_valid;
    logic out_ready;
    logic error;

    logic [31:0] samples [0:NUM_SAMPLES-1];
    int sample_idx;
    int ones_count;
    int total_bits;
    int cycles_elapsed;
    real ones_percentage;

    trng_core #(
        .FIFO_DEPTH(16),
        .FIFO_ADDR_WIDTH(4),
        .C_RCT(8'd30),
        .C_APT_HIGH(11'd640),
        .C_APT_LOW(11'd384)
    ) u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .out_data(out_data),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .error(error)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    task automatic reset_dut();
    begin
        rst_n = 1'b0;
        enable = 1'b0;
        out_ready = 1'b0;
        repeat (10) @(posedge clk);
        #1;
        rst_n = 1'b1;
        repeat (5) @(posedge clk);
        #1;
    end
    endtask

    initial begin
        reset_dut();

        enable = 1'b1;
        out_ready = 1'b1;
        sample_idx = 0;
        ones_count = 0;
        total_bits = 0;
        cycles_elapsed = 0;

        while (sample_idx < NUM_SAMPLES) begin
            @(posedge clk);
            cycles_elapsed++;
            if (out_valid && out_ready) begin
                samples[sample_idx] = out_data;
                sample_idx++;
            end
        end

        for (int i = 0; i < NUM_SAMPLES; i++) begin
            for (int j = 0; j < 32; j++) begin
                if (samples[i][j]) begin
                    ones_count++;
                end
                total_bits++;
            end
        end

        ones_percentage = (real'(ones_count) / real'(total_bits)) * 100.0;
        $display("TRNG Monobit Test: %0d / %0d bits are 1s (%f%%)", ones_count, total_bits, ones_percentage);
        if (ones_percentage >= 45.0 && ones_percentage <= 55.0) begin
            $display("TRNG Monobit Test: PASSED");
        end else begin
            $display("TRNG Monobit Test: FAILED");
        end
        $display("TRNG Throughput: %f cycles per 32-bit word", real'(cycles_elapsed) / real'(NUM_SAMPLES));

        enable = 1'b0;
        repeat (100) @(posedge clk);

        while (out_valid) begin
            @(posedge clk);
            if (out_valid && out_ready) begin
                $display("Drained word after disable: %h", out_data);
            end
        end
        $display("FIFO drained completely");

        enable = 1'b1;
        sample_idx = 0;
        while (sample_idx < 100) begin
            @(posedge clk);
            out_ready = $urandom_range(0, 1);
            if (out_valid && out_ready) begin
                sample_idx++;
            end
        end
        $display("Backpressure test complete with 100 samples");

        $display("Injecting stuck-at-1 fault on raw_bit to test RCT...");
        reset_dut();
        enable = 1'b1;
        force u_dut.raw_bit = 1'b1;
        
        fork
            begin
                wait (error == 1'b1);
                $display("RCT Test Passed: Error signal detected.");
            end
            begin
                repeat (100) @(posedge clk);
                if (error == 1'b0) begin
                    $display("RCT Test Failed: Error signal not detected after 100 cycles.");
                end
            end
        join
        release u_dut.raw_bit;

        $display("Injecting biased stream (95%% ones) on raw_bit to test APT...");
        reset_dut();
        enable = 1'b1;
        
        fork
            begin
                wait (error == 1'b1);
                $display("APT Test Passed: Error signal detected.");
            end
            begin
                for (int k = 0; k < 1200; k++) begin
                    @(posedge clk);
                    if ($urandom_range(0, 99) < 95) begin
                        force u_dut.raw_bit = 1'b1;
                    end else begin
                        force u_dut.raw_bit = 1'b0;
                    end
                end
                if (error == 1'b0) begin
                    $display("APT Test Failed: Error signal not detected after 1200 cycles.");
                end
            end
        join
        release u_dut.raw_bit;

        #100;
        $finish;
    end

endmodule
