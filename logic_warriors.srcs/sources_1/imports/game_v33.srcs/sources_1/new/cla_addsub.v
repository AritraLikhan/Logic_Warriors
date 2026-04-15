

module cla_addsub #(
    parameter W = 4
)(
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    input  wire         add_sub,
    output wire [W-1:0] sum,
    output wire         cout,
    output wire         overflow
);
    wire [W-1:0] bx;
    wire [W-1:0] p;
    wire [W-1:0] g;
    wire [W:0] c;

    assign bx   = b ^ {W{add_sub}};
    assign c[0] = add_sub;

    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin : GEN_CLA
            assign p[i]   = a[i] ^ bx[i];
            assign g[i]   = a[i] & bx[i];
            assign c[i+1] = g[i] | (p[i] & c[i]);
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate

    assign cout     = c[W];
    assign overflow = c[W] ^ c[W-1];
endmodule
