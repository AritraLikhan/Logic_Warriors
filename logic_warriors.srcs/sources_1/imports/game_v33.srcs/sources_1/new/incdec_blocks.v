module inc_n #(
    parameter W = 4
)(
    input  wire [W-1:0] a,
    output wire [W-1:0] y
);
    cla_addsub #(.W(W)) u_inc (.a(a), .b({{W-1{1'b0}},1'b1}), .add_sub(1'b0), .sum(y), .cout(), .overflow());
endmodule

module dec_n #(
    parameter W = 4
)(
    input  wire [W-1:0] a,
    output wire [W-1:0] y
);
    cla_addsub #(.W(W)) u_dec (.a(a), .b({{W-1{1'b0}},1'b1}), .add_sub(1'b1), .sum(y), .cout(), .overflow());
endmodule
