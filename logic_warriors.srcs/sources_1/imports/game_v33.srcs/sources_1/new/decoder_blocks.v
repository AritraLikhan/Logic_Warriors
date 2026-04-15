module decoder2to4 (
    input  wire [1:0] a,
    output wire [3:0] y
);
    assign y[0] = ~a[1] & ~a[0];
    assign y[1] = ~a[1] &  a[0];
    assign y[2] =  a[1] & ~a[0];
    assign y[3] =  a[1] &  a[0];
endmodule

module decoder3to8 (
    input  wire [2:0] a,
    output wire [7:0] y
);
    assign y[0] = ~a[2] & ~a[1] & ~a[0];
    assign y[1] = ~a[2] & ~a[1] &  a[0];
    assign y[2] = ~a[2] &  a[1] & ~a[0];
    assign y[3] = ~a[2] &  a[1] &  a[0];
    assign y[4] =  a[2] & ~a[1] & ~a[0];
    assign y[5] =  a[2] & ~a[1] &  a[0];
    assign y[6] =  a[2] &  a[1] & ~a[0];
    assign y[7] =  a[2] &  a[1] &  a[0];
endmodule
