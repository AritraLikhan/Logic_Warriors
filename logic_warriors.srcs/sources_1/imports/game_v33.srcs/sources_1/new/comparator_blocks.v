module eq_n #(
    parameter W = 4,
    parameter SIGNED_MODE = 0
)(
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    output wire         eq
);
    wire lt_unused, gt_unused;

    cmp_n #(.W(W), .SIGNED_MODE(SIGNED_MODE)) u_cmp (.a(a), .b(b), .eq(eq), .lt(lt_unused), .gt(gt_unused));
endmodule

module lt_n #(
    parameter W = 4,
    parameter SIGNED_MODE = 0
)(
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    output wire         lt
);
    wire eq_unused, gt_unused;

    cmp_n #(.W(W), .SIGNED_MODE(SIGNED_MODE)) u_cmp (.a(a), .b(b), .eq(eq_unused), .lt(lt), .gt(gt_unused));
endmodule

module gt_n #(
    parameter W = 4,
    parameter SIGNED_MODE = 0
)(
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    output wire         gt
);
    wire eq_unused, lt_unused;

    cmp_n #(.W(W), .SIGNED_MODE(SIGNED_MODE)) u_cmp (.a(a), .b(b), .eq(eq_unused), .lt(lt_unused), .gt(gt));
endmodule

module le_n #(
    parameter W = 4,
    parameter SIGNED_MODE = 0
)(
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    output wire         le
);
    wire eq_w, lt_w, gt_unused;

    cmp_n #(.W(W), .SIGNED_MODE(SIGNED_MODE)) u_cmp (.a(a), .b(b), .eq(eq_w), .lt(lt_w), .gt(gt_unused));
    assign le = eq_w | lt_w;
endmodule

module ge_n #(
    parameter W = 4,
    parameter SIGNED_MODE = 0
)(
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    output wire         ge
);
    wire eq_w, lt_unused, gt_w;

    cmp_n #(.W(W), .SIGNED_MODE(SIGNED_MODE)) u_cmp (.a(a), .b(b), .eq(eq_w), .lt(lt_unused), .gt(gt_w));
    assign ge = eq_w | gt_w;
endmodule
