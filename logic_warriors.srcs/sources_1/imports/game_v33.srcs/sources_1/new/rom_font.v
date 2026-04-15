

module rom_font (
    input  wire [4:0] code,
    output reg  [7:0] seg
);
    // seg = {dp,g,f,e,d,c,b,a}, active-low
    localparam [4:0] F_0     = 5'd0;
    localparam [4:0] F_1     = 5'd1;
    localparam [4:0] F_2     = 5'd2;
    localparam [4:0] F_3     = 5'd3;
    localparam [4:0] F_4     = 5'd4;
    localparam [4:0] F_5     = 5'd5;
    localparam [4:0] F_6     = 5'd6;
    localparam [4:0] F_7     = 5'd7;
    localparam [4:0] F_8     = 5'd8;
    localparam [4:0] F_9     = 5'd9;
    localparam [4:0] F_A     = 5'd10;
    localparam [4:0] F_B     = 5'd11;
    localparam [4:0] F_H     = 5'd12;
    localparam [4:0] F_I     = 5'd13;
    localparam [4:0] F_G     = 5'd14;
    localparam [4:0] F_O     = 5'd15;
    localparam [4:0] F_W1    = 5'd16;
    localparam [4:0] F_W2    = 5'd17;
    localparam [4:0] F_W3    = 5'd18;
    localparam [4:0] F_L     = 5'd19;
    localparam [4:0] F_MINUS = 5'd20;
    localparam [4:0] F_BLANK = 5'd31;

    always @(*) begin
        case (code)
            F_0:     seg = 8'b11000000;
            F_1:     seg = 8'b11111001;
            F_2:     seg = 8'b10100100;
            F_3:     seg = 8'b10110000;
            F_4:     seg = 8'b10011001;
            F_5:     seg = 8'b10010010;
            F_6:     seg = 8'b10000010;
            F_7:     seg = 8'b11111000;
            F_8:     seg = 8'b10000000;
            F_9:     seg = 8'b10010000;
            F_A:     seg = 8'b10001000; // a,b,c,e,f,g
            F_B:     seg = 8'b10000000; // all segments on per project
            F_H:     seg = 8'b10001001; // b,c,e,f,g
            F_I:     seg = 8'b11001111; // e,f
            F_G:     seg = 8'b11000010; // a,c,d,e,f
            F_O:     seg = 8'b11000000; // all except g
            F_W1:    seg = 8'b11100011; // f,e,d,c
            F_W2:    seg = 8'b10111111; // g only
            F_W3:    seg = 8'b11100011; // e,d,c
            F_L:     seg = 8'b11000111; // f,e,d
            F_MINUS: seg = 8'b10111111; // g only
            default: seg = 8'b11111111; // blank
        endcase
    end
endmodule
