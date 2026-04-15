module mux2_n #(
    parameter W = 4
)(
    input  wire [W-1:0] d0,
    input  wire [W-1:0] d1,
    input  wire         sel,
    output wire [W-1:0] y
);
    assign y = ({W{~sel}} & d0) | ({W{sel}} & d1);
endmodule

module onehot_mux4_n #(
    parameter W = 4
)(
    input  wire [W-1:0] d0,
    input  wire [W-1:0] d1,
    input  wire [W-1:0] d2,
    input  wire [W-1:0] d3,
    input  wire [3:0]   sel,
    output wire [W-1:0] y
);
    wire [W-1:0] y0 = d0 & {W{sel[0]}};
    wire [W-1:0] y1 = d1 & {W{sel[1]}};
    wire [W-1:0] y2 = d2 & {W{sel[2]}};
    wire [W-1:0] y3 = d3 & {W{sel[3]}};

    assign y = y0 | y1 | y2 | y3;
endmodule

module mux4_n #(
    parameter W = 4
)(
    input  wire [W-1:0] d0,
    input  wire [W-1:0] d1,
    input  wire [W-1:0] d2,
    input  wire [W-1:0] d3,
    input  wire [1:0]   sel,
    output wire [W-1:0] y
);
    wire [3:0] sel_oh;

    decoder2to4 u_dec (.a(sel), .y(sel_oh));
    onehot_mux4_n #(.W(W)) u_mux (.d0(d0), .d1(d1), .d2(d2), .d3(d3), .sel(sel_oh), .y(y));
endmodule
