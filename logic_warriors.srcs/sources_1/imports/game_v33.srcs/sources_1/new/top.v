

module top (
    input  wire       clk,
    input  wire       btnC,
    input  wire       btnU,
    input  wire       btnL,
    input  wire       btnR,
    input  wire       btnD,
    input  wire [15:0] sw,
    output wire [15:0] led,
    output wire [6:0] seg,
    output wire       dp,
    output wire [3:0] an
);
    wire rst;
    wire btnc_pulse, btnu_pulse, btnl_pulse, btnr_pulse, btnd_pulse;
    wire btnc_level_unused, btnu_level_unused, btnl_level_unused, btnr_level_unused, btnd_level_unused;

    wire [1:0] display_mode;
    wire       winner;
    wire [3:0] player_hp;
    wire [3:0] cpu_hp;
    wire [1:0] player_action_reg;
    wire [1:0] cpu_action_turn;
    wire signed [3:0] player_gain;
    wire signed [3:0] cpu_gain;
    wire [7:0] digit3, digit2, digit1, digit0;
    wire [7:0] round_counter_unused;
    wire running_unused;

    assign rst = sw[15]; // soft reset; BTNC remains run/pause per project behavior

    debounce_edge u_db_c (.clk(clk), .rst(rst), .din(btnC), .level(btnc_level_unused), .pulse(btnc_pulse));
    debounce_edge u_db_u (.clk(clk), .rst(rst), .din(btnU), .level(btnu_level_unused), .pulse(btnu_pulse));
    debounce_edge u_db_l (.clk(clk), .rst(rst), .din(btnL), .level(btnl_level_unused), .pulse(btnl_pulse));
    debounce_edge u_db_r (.clk(clk), .rst(rst), .din(btnR), .level(btnr_level_unused), .pulse(btnr_pulse));
    debounce_edge u_db_d (.clk(clk), .rst(rst), .din(btnD), .level(btnd_level_unused), .pulse(btnd_pulse));

    game_controller u_controller (
        .clk             (clk),
        .rst             (rst),
        .btnc_pulse      (btnc_pulse),
        .btnl_pulse      (btnl_pulse),
        .btnr_pulse      (btnr_pulse),
        .btnu_pulse      (btnu_pulse),
        .btnd_pulse      (btnd_pulse),
        .display_mode    (display_mode),
        .winner          (winner),
        .player_hp       (player_hp),
        .cpu_hp          (cpu_hp),
        .player_action_reg(player_action_reg),
        .cpu_action_turn (cpu_action_turn),
        .player_gain     (player_gain),
        .cpu_gain        (cpu_gain),
        .round_counter   (round_counter_unused),
        .running         (running_unused)
    );

    display_mux u_mux (
        .display_mode (display_mode),
        .winner       (winner),
        .player_hp    (player_hp),
        .cpu_hp       (cpu_hp),
        .player_action(player_action_reg),
        .cpu_action   (cpu_action_turn),
        .player_gain  (player_gain),
        .cpu_gain     (cpu_gain),
        .digit3       (digit3),
        .digit2       (digit2),
        .digit1       (digit1),
        .digit0       (digit0)
    );

    display_scan u_scan (
        .clk   (clk),
        .rst   (rst),
        .digit3(digit3),
        .digit2(digit2),
        .digit1(digit1),
        .digit0(digit0),
        .an    (an),
        .seg   (seg),
        .dp    (dp)
    );

    assign led[3:0]   = player_hp;
    assign led[7:4]   = cpu_hp;
    assign led[8]     = running_unused;
    assign led[9]     = winner;
    assign led[15:10] = 6'b0;
endmodule
