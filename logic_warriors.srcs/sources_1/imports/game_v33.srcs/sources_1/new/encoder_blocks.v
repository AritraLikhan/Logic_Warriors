module encoder4to2 (
    input  wire [3:0] in,
    output wire [1:0] out
);
    assign out[1] = in[2] | in[3];
    assign out[0] = in[1] | in[3];
endmodule

module onehot_priority_encoder4 (
    input  wire [3:0] req,
    output wire [3:0] grant,
    output wire [1:0] enc,
    output wire       valid
);
    assign grant[0] = req[0];
    assign grant[1] = ~req[0] & req[1];
    assign grant[2] = ~req[0] & ~req[1] & req[2];
    assign grant[3] = ~req[0] & ~req[1] & ~req[2] & req[3];

    reduce_or_n #(.W(4)) u_valid (.din(req), .dout(valid));
    encoder4to2 u_enc (.in(grant), .out(enc));
endmodule
