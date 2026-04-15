

module cmp_n #(
    parameter W = 4,
    parameter SIGNED_MODE = 0
)(
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    output wire         eq,
    output wire         lt,
    output wire         gt
);
    wire [W-1:0] diff;
    wire cout;
    wire overflow;

    cla_addsub #(.W(W)) u_sub (
        .a(a),
        .b(b),
        .add_sub(1'b1),
        .sum(diff),
        .cout(cout),
        .overflow(overflow)
    );

    assign eq = ~(|diff);
    assign lt = SIGNED_MODE ? (diff[W-1] ^ overflow) : ~cout;
    assign gt = (~lt) & (~eq);
endmodule
