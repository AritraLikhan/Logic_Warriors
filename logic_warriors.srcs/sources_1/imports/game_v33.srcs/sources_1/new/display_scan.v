module display_scan #(
    parameter integer CLK_HZ   = 100_000_000,
    parameter integer DIGIT_HZ = 1000
)(
    input  wire clk,
    input  wire rst,
    input  wire [7:0] digit3,
    input  wire [7:0] digit2,
    input  wire [7:0] digit1,
    input  wire [7:0] digit0,
    output reg  [3:0] an,
    output reg  [6:0] seg,
    output reg        dp
);
    localparam integer DIV_MAX = CLK_HZ / (DIGIT_HZ * 4);
    localparam [31:0] DIV_LAST = DIV_MAX - 1;

    reg  [31:0] divcnt;
    reg  [1:0]  scan_idx;
    reg  [7:0]  curpat;
    wire [31:0] divcnt_inc;
    wire [1:0]  scan_idx_inc;
    wire        div_wrap;
    wire [3:0]  an_w;
    wire [7:0]  curpat_w;

    inc_n #(.W(32)) u_div_inc (.a(divcnt), .y(divcnt_inc));
    inc_n #(.W(2))  u_idx_inc (.a(scan_idx), .y(scan_idx_inc));
    eq_n  #(.W(32), .SIGNED_MODE(0)) u_div_eq (.a(divcnt), .b(DIV_LAST), .eq(div_wrap));

    mux4_n #(.W(4)) u_an_mux (
        .d0 (4'b1110),
        .d1 (4'b1101),
        .d2 (4'b1011),
        .d3 (4'b0111),
        .sel(scan_idx),
        .y  (an_w)
    );

    mux4_n #(.W(8)) u_pat_mux (
        .d0 (digit0),
        .d1 (digit1),
        .d2 (digit2),
        .d3 (digit3),
        .sel(scan_idx),
        .y  (curpat_w)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            divcnt   <= 32'd0;
            scan_idx <= 2'd0;
        end else if (div_wrap) begin
            divcnt   <= 32'd0;
            scan_idx <= scan_idx_inc;
        end else begin
            divcnt <= divcnt_inc;
        end
    end

    always @(*) begin
        an     = an_w;
        curpat = curpat_w;
        seg    = curpat_w[6:0];
        dp     = curpat_w[7];
    end
endmodule
