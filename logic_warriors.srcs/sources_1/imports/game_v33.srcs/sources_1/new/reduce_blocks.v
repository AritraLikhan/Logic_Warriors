module reduce_and_n #(
    parameter W = 4
)(
    input  wire [W-1:0] din,
    output wire         dout
);
    wire [W:0] chain;
    genvar i;

    assign chain[0] = 1'b1;
    generate
        for (i = 0; i < W; i = i + 1) begin : GEN_AND
            assign chain[i+1] = chain[i] & din[i];
        end
    endgenerate
    assign dout = chain[W];
endmodule

module reduce_or_n #(
    parameter W = 4
)(
    input  wire [W-1:0] din,
    output wire         dout
);
    wire [W:0] chain;
    genvar i;

    assign chain[0] = 1'b0;
    generate
        for (i = 0; i < W; i = i + 1) begin : GEN_OR
            assign chain[i+1] = chain[i] | din[i];
        end
    endgenerate
    assign dout = chain[W];
endmodule

module reduce_xor_n #(
    parameter W = 4
)(
    input  wire [W-1:0] din,
    output wire         dout
);
    wire [W:0] chain;
    genvar i;

    assign chain[0] = 1'b0;
    generate
        for (i = 0; i < W; i = i + 1) begin : GEN_XOR
            assign chain[i+1] = chain[i] ^ din[i];
        end
    endgenerate
    assign dout = chain[W];
endmodule
