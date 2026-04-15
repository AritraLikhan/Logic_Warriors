module clamp_range_n #(
    parameter W = 5,
    parameter SIGNED_MODE = 0
)(
    input  wire [W-1:0] in,
    input  wire [W-1:0] min_val,
    input  wire [W-1:0] max_val,
    output wire [W-1:0] out,
    output wire         low_hit,
    output wire         high_hit
);
    wire [W-1:0] low_mux;

    lt_n #(.W(W), .SIGNED_MODE(SIGNED_MODE)) u_lt (.a(in), .b(min_val), .lt(low_hit));
    gt_n #(.W(W), .SIGNED_MODE(SIGNED_MODE)) u_gt (.a(in), .b(max_val), .gt(high_hit));
    mux2_n #(.W(W)) u_low_mux (.d0(in), .d1(min_val), .sel(low_hit), .y(low_mux));
    mux2_n #(.W(W)) u_high_mux (.d0(low_mux), .d1(max_val), .sel(high_hit), .y(out));
endmodule
