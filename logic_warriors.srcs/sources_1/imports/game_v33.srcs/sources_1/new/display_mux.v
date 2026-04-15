module display_mux (
    input  wire [1:0]  display_mode,
    input  wire        winner,
    input  wire [3:0]  player_hp,
    input  wire [3:0]  cpu_hp,
    input  wire [1:0]  player_action,
    input  wire [1:0]  cpu_action,
    input  wire signed [3:0] player_gain,
    input  wire signed [3:0] cpu_gain,
    output wire [7:0] digit3,
    output wire [7:0] digit2,
    output wire [7:0] digit1,
    output wire [7:0] digit0
);
    localparam [1:0] MODE_GO        = 2'd0;
    localparam [1:0] MODE_ACTION    = 2'd1;
    localparam [1:0] MODE_RESULT    = 2'd2;
    localparam [1:0] MODE_GAME_OVER = 2'd3;

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

    reg [4:0] code3, code2, code1, code0;

    function [4:0] action_code;
        input [1:0] a;
        begin
            case (a)
                2'd0: action_code = F_A;
                2'd1: action_code = F_B;
                2'd2: action_code = F_H;
                default: action_code = F_I;
            endcase
        end
    endfunction

    function [4:0] mag_code;
        input signed [3:0] g;
        reg signed [4:0] g_ext;
        begin
            g_ext = {g[3], g};
            if (g_ext < 0)
                mag_code = -g_ext;
            else
                mag_code = g_ext[4:0];
        end
    endfunction

    function [4:0] sign_code;
        input signed [3:0] g;
        begin
            if (g < 0)
                sign_code = F_MINUS;
            else
                sign_code = F_BLANK;
        end
    endfunction

    always @(*) begin
        case (display_mode)
            MODE_GO: begin
                code3 = F_G;
                code2 = F_O;
                code1 = F_BLANK;
                code0 = F_BLANK;
            end
            MODE_ACTION: begin
                code3 = {1'b0, player_hp};
                code2 = action_code(player_action);
                code1 = action_code(cpu_action);
                code0 = {1'b0, cpu_hp};
            end
            MODE_RESULT: begin
                code3 = sign_code(player_gain);
                code2 = mag_code(player_gain);
                code1 = sign_code(cpu_gain);
                code0 = mag_code(cpu_gain);
            end
            default: begin
                if (winner) begin
                    code3 = F_W1;
                    code2 = F_W2;
                    code1 = F_W3;
                    code0 = F_BLANK;
                end else begin
                    code3 = F_L;
                    code2 = F_BLANK;
                    code1 = F_BLANK;
                    code0 = F_BLANK;
                end
            end
        endcase
    end

    rom_font u3 (.code(code3), .seg(digit3));
    rom_font u2 (.code(code2), .seg(digit2));
    rom_font u1 (.code(code1), .seg(digit1));
    rom_font u0 (.code(code0), .seg(digit0));
endmodule
