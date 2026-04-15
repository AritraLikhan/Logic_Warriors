

module gain_table (
    input  wire [1:0] player_action,
    input  wire [1:0] cpu_action,
    output reg  signed [3:0] player_gain,
    output reg  signed [3:0] cpu_gain
);
    localparam [1:0] ACT_A = 2'd0;
    localparam [1:0] ACT_B = 2'd1;
    localparam [1:0] ACT_H = 2'd2;
    localparam [1:0] ACT_I = 2'd3;

    always @(*) begin
        player_gain = 4'sd0;
        cpu_gain    = 4'sd0;

        case ({player_action, cpu_action})
            {ACT_A, ACT_A}: begin player_gain = -4'sd1; cpu_gain = -4'sd1; end
            {ACT_B, ACT_B}: begin player_gain =  4'sd0; cpu_gain =  4'sd0; end
            {ACT_H, ACT_H}: begin player_gain =  4'sd2; cpu_gain =  4'sd2; end
            {ACT_I, ACT_I}: begin player_gain =  4'sd0; cpu_gain =  4'sd0; end
            {ACT_A, ACT_B}: begin player_gain =  4'sd0; cpu_gain =  4'sd0; end
            {ACT_B, ACT_A}: begin player_gain =  4'sd0; cpu_gain =  4'sd0; end
            {ACT_A, ACT_H}: begin player_gain =  4'sd0; cpu_gain = -4'sd1; end
            {ACT_H, ACT_A}: begin player_gain = -4'sd1; cpu_gain =  4'sd0; end
            {ACT_A, ACT_I}: begin player_gain =  4'sd0; cpu_gain = -4'sd2; end
            {ACT_I, ACT_A}: begin player_gain = -4'sd2; cpu_gain =  4'sd0; end
            {ACT_B, ACT_H}: begin player_gain =  4'sd0; cpu_gain =  4'sd2; end
            {ACT_H, ACT_B}: begin player_gain =  4'sd2; cpu_gain =  4'sd0; end
            {ACT_B, ACT_I}: begin player_gain =  4'sd0; cpu_gain =  4'sd0; end
            {ACT_I, ACT_B}: begin player_gain =  4'sd0; cpu_gain =  4'sd0; end
            {ACT_H, ACT_I}: begin player_gain =  4'sd2; cpu_gain =  4'sd0; end
            {ACT_I, ACT_H}: begin player_gain =  4'sd0; cpu_gain =  4'sd2; end
            default:        begin player_gain =  4'sd0; cpu_gain =  4'sd0; end
        endcase
    end
endmodule
