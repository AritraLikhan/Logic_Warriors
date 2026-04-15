module alu_small (
    input  wire [3:0]         hp_in,
    input  wire signed [3:0]  gain_in,
    output wire [3:0]         hp_next,
    output wire signed [3:0]  hp_delta,
    output wire               is_zero,
    output wire               lt_zero_raw,
    output wire               gt_nine_raw
);
    wire [4:0] hp_ext   = {1'b0, hp_in};
    wire [4:0] gain_ext = {gain_in[3], gain_in};
    wire [4:0] raw_sum;
    wire raw_cout, raw_ovf;
    wire [4:0] clamped_sum;
    wire [4:0] delta_ext;
    wire delta_cout_unused, delta_ovf_unused;
    wire hp_eq0;
    wire hp_lt0_unused, hp_gt0_unused;

    cla_addsub #(.W(5)) u_add (
        .a(hp_ext),
        .b(gain_ext),
        .add_sub(1'b0),
        .sum(raw_sum),
        .cout(raw_cout),
        .overflow(raw_ovf)
    );

    clamp_range_n #(.W(5), .SIGNED_MODE(1)) u_clamp (
        .in       (raw_sum),
        .min_val  (5'sd0),
        .max_val  (5'sd9),
        .out      (clamped_sum),
        .low_hit  (lt_zero_raw),
        .high_hit (gt_nine_raw)
    );

    cla_addsub #(.W(5)) u_delta (
        .a(clamped_sum),
        .b(hp_ext),
        .add_sub(1'b1),
        .sum(delta_ext),
        .cout(delta_cout_unused),
        .overflow(delta_ovf_unused)
    );

    cmp_n #(.W(5), .SIGNED_MODE(0)) u_cmp_hp0 (
        .a(clamped_sum), .b(5'd0), .eq(hp_eq0), .lt(hp_lt0_unused), .gt(hp_gt0_unused)
    );

    assign hp_next  = clamped_sum[3:0];
    assign hp_delta = delta_ext[3:0];
    assign is_zero  = hp_eq0;
endmodule
