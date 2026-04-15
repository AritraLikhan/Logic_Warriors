module game_controller #(
    parameter integer CLK_HZ            = 100_000_000,
    parameter integer ACTION_VIEW_MS    = 700,
    parameter integer RESULT_VIEW_MS    = 700
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       btnc_pulse,
    input  wire       btnl_pulse,
    input  wire       btnr_pulse,
    input  wire       btnu_pulse,
    input  wire       btnd_pulse,

    output reg  [1:0] display_mode,
    output reg        winner,
    output reg  [3:0] player_hp,
    output reg  [3:0] cpu_hp,
    output reg  [1:0] player_action_reg,
    output reg  [1:0] cpu_action_turn,
    output wire signed [3:0] player_gain,
    output wire signed [3:0] cpu_gain,
    output reg  [7:0] round_counter,
    output reg        running
);
    localparam [1:0] MODE_GO        = 2'd0;
    localparam [1:0] MODE_ACTION    = 2'd1;
    localparam [1:0] MODE_RESULT    = 2'd2;
    localparam [1:0] MODE_GAME_OVER = 2'd3;

    localparam [1:0] ACT_A = 2'd0;
    localparam [1:0] ACT_B = 2'd1;
    localparam [1:0] ACT_H = 2'd2;
    localparam [1:0] ACT_I = 2'd3;

    localparam [2:0] S_WAIT         = 3'd0;
    localparam [2:0] S_REQ_CPU      = 3'd1;
    localparam [2:0] S_SHOW_ACTIONS = 3'd2;
    localparam [2:0] S_SHOW_RESULTS = 3'd3;
    localparam [2:0] S_UPDATE       = 3'd4;
    localparam [2:0] S_GAME_OVER    = 3'd5;

    localparam integer ACTION_TICKS = (CLK_HZ / 1000) * ACTION_VIEW_MS;
    localparam integer RESULT_TICKS = (CLK_HZ / 1000) * RESULT_VIEW_MS;
    localparam [31:0] ACTION_LAST   = ACTION_TICKS - 1;
    localparam [31:0] RESULT_LAST   = RESULT_TICKS - 1;

    reg [2:0]  state;
    reg [31:0] timer_cnt;
    wire [7:0] state_oh;
    wire st_wait, st_req_cpu, st_show_actions, st_show_results, st_update, st_game_over;
    wire restart_pulse_w;
    wire update_hist_pulse_w;
    wire [1:0] cpu_action_reg_w;
    wire       player_repeat_penalty;
    wire       cpu_repeat_penalty;
    wire [3:0] player_hp_next;
    wire [3:0] cpu_hp_next;
    wire signed [3:0] player_gain_base;
    wire signed [3:0] cpu_gain_base;
    wire signed [3:0] player_gain_pen;
    wire signed [3:0] cpu_gain_pen;
    wire signed [3:0] player_delta_actual;
    wire signed [3:0] cpu_delta_actual;
    wire player_is_zero;
    wire cpu_is_zero;
    wire player_lt_zero_unused, player_gt_nine_unused;
    wire cpu_lt_zero_unused, cpu_gt_nine_unused;
    wire [31:0] timer_cnt_inc;
    wire [7:0] round_counter_inc;
    wire action_timer_done;
    wire result_timer_done;
    wire [1:0] player_action_req;
    wire [3:0] player_action_grant;
    wire player_action_valid;

    decoder3to8 u_state_dec (.a(state), .y(state_oh));
    assign st_wait         = state_oh[0];
    assign st_req_cpu      = state_oh[1];
    assign st_show_actions = state_oh[2];
    assign st_show_results = state_oh[3];
    assign st_update       = state_oh[4];
    assign st_game_over    = state_oh[5];

    assign restart_pulse_w     = btnc_pulse & st_game_over;
    assign update_hist_pulse_w = st_update;

    dec_n  #(.W(4))  u_pgain_dec (.a(player_gain_base), .y(player_gain_pen));
    dec_n  #(.W(4))  u_cgain_dec (.a(cpu_gain_base), .y(cpu_gain_pen));
    mux2_n #(.W(4))  u_pgain_mux (.d0(player_gain_base), .d1(player_gain_pen), .sel(player_repeat_penalty), .y(player_gain));
    mux2_n #(.W(4))  u_cgain_mux (.d0(cpu_gain_base), .d1(cpu_gain_pen), .sel(cpu_repeat_penalty), .y(cpu_gain));
    inc_n  #(.W(32)) u_timer_inc (.a(timer_cnt), .y(timer_cnt_inc));
    inc_n  #(.W(8))  u_round_inc (.a(round_counter), .y(round_counter_inc));
    eq_n   #(.W(32), .SIGNED_MODE(0)) u_action_done (.a(timer_cnt), .b(ACTION_LAST), .eq(action_timer_done));
    eq_n   #(.W(32), .SIGNED_MODE(0)) u_result_done (.a(timer_cnt), .b(RESULT_LAST), .eq(result_timer_done));

    priority_select4 #(.W(2)) u_player_action_sel (
        .req   ({btnd_pulse, btnu_pulse, btnr_pulse, btnl_pulse}),
        .d0    (ACT_A),
        .d1    (ACT_B),
        .d2    (ACT_H),
        .d3    (ACT_I),
        .y     (player_action_req),
        .grant (player_action_grant),
        .valid (player_action_valid)
    );

    gain_table u_gain_table (
        .player_action (player_action_reg),
        .cpu_action    (cpu_action_turn),
        .player_gain   (player_gain_base),
        .cpu_gain      (cpu_gain_base)
    );

    alu_small u_player_alu (
        .hp_in        (player_hp),
        .gain_in      (player_gain),
        .hp_next      (player_hp_next),
        .hp_delta     (player_delta_actual),
        .is_zero      (player_is_zero),
        .lt_zero_raw  (player_lt_zero_unused),
        .gt_nine_raw  (player_gt_nine_unused)
    );

    alu_small u_cpu_alu (
        .hp_in        (cpu_hp),
        .gain_in      (cpu_gain),
        .hp_next      (cpu_hp_next),
        .hp_delta     (cpu_delta_actual),
        .is_zero      (cpu_is_zero),
        .lt_zero_raw  (cpu_lt_zero_unused),
        .gt_nine_raw  (cpu_gt_nine_unused)
    );

    cpu_ai_rules u_cpu_rules (
        .clk                   (clk),
        .rst                   (rst),
        .restart_pulse         (restart_pulse_w),
        .update_hist_pulse     (update_hist_pulse_w),
        .player_hp             (player_hp),
        .cpu_hp                (cpu_hp),
        .player_hp_after_turn  (player_hp_next),
        .player_action_reg     (player_action_reg),
        .cpu_action_taken      (cpu_action_turn),
        .cpu_gain_this_turn    (cpu_delta_actual),
        .cpu_action_reg        (cpu_action_reg_w),
        .player_repeat_penalty (player_repeat_penalty),
        .cpu_repeat_penalty    (cpu_repeat_penalty)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state             <= S_WAIT;
            display_mode      <= MODE_GO;
            winner            <= 1'b0;
            player_hp         <= 4'd9;
            cpu_hp            <= 4'd9;
            player_action_reg <= ACT_I;
            cpu_action_turn   <= ACT_B;
            round_counter     <= 8'd0;
            running           <= 1'b0;
            timer_cnt         <= 32'd0;
        end else begin
            if (btnc_pulse) begin
                if (st_game_over) begin
                    state             <= S_WAIT;
                    display_mode      <= MODE_GO;
                    winner            <= 1'b0;
                    player_hp         <= 4'd9;
                    cpu_hp            <= 4'd9;
                    player_action_reg <= ACT_I;
                    cpu_action_turn   <= ACT_B;
                    round_counter     <= 8'd0;
                    running           <= 1'b0;
                    timer_cnt         <= 32'd0;
                end else begin
                    running <= ~running;
                end
            end

            case (state)
                S_WAIT: begin
                    if (~running && (round_counter == 0))
                        display_mode <= MODE_GO;
                    else
                        display_mode <= MODE_ACTION;

                    timer_cnt <= 32'd0;

                    if (running && player_action_valid) begin
                        player_action_reg <= player_action_req;
                        state             <= S_REQ_CPU;
                    end
                end

                S_REQ_CPU: begin
                    display_mode    <= MODE_ACTION;
                    cpu_action_turn <= cpu_action_reg_w;
                    timer_cnt       <= 32'd0;
                    state           <= S_SHOW_ACTIONS;
                end

                S_SHOW_ACTIONS: begin
                    display_mode <= MODE_ACTION;
                    if (running) begin
                        if (action_timer_done) begin
                            timer_cnt <= 32'd0;
                            state     <= S_SHOW_RESULTS;
                        end else begin
                            timer_cnt <= timer_cnt_inc;
                        end
                    end
                end

                S_SHOW_RESULTS: begin
                    display_mode <= MODE_RESULT;
                    if (running) begin
                        if (result_timer_done) begin
                            timer_cnt <= 32'd0;
                            state     <= S_UPDATE;
                        end else begin
                            timer_cnt <= timer_cnt_inc;
                        end
                    end
                end

                S_UPDATE: begin
                    display_mode  <= MODE_RESULT;
                    player_hp     <= player_hp_next;
                    cpu_hp        <= cpu_hp_next;
                    round_counter <= round_counter_inc;

                    if (player_is_zero || cpu_is_zero) begin
                        winner       <= cpu_is_zero & ~player_is_zero;
                        display_mode <= MODE_GAME_OVER;
                        running      <= 1'b0;
                        state        <= S_GAME_OVER;
                    end else begin
                        state        <= S_WAIT;
                        display_mode <= MODE_ACTION;
                    end
                end

                S_GAME_OVER: begin
                    display_mode <= MODE_GAME_OVER;
                end

                default: begin
                    display_mode <= MODE_GAME_OVER;
                    state        <= S_GAME_OVER;
                end
            endcase
        end
    end
endmodule

module game_cu_fsm #(
    parameter integer CLK_HZ            = 100_000_000,
    parameter integer ACTION_VIEW_MS    = 700,
    parameter integer RESULT_VIEW_MS    = 700
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       btnc_pulse,
    input  wire       btnl_pulse,
    input  wire       btnr_pulse,
    input  wire       btnu_pulse,
    input  wire       btnd_pulse,

    output wire [1:0] display_mode,
    output wire       winner,
    output wire [3:0] player_hp,
    output wire [3:0] cpu_hp,
    output wire [1:0] player_action_reg,
    output wire [1:0] cpu_action_turn,
    output wire signed [3:0] player_gain,
    output wire signed [3:0] cpu_gain,
    output wire [7:0] round_counter,
    output wire       running
);
    game_controller #(
        .CLK_HZ         (CLK_HZ),
        .ACTION_VIEW_MS (ACTION_VIEW_MS),
        .RESULT_VIEW_MS (RESULT_VIEW_MS)
    ) u_game_controller (
        .clk              (clk),
        .rst              (rst),
        .btnc_pulse       (btnc_pulse),
        .btnl_pulse       (btnl_pulse),
        .btnr_pulse       (btnr_pulse),
        .btnu_pulse       (btnu_pulse),
        .btnd_pulse       (btnd_pulse),
        .display_mode     (display_mode),
        .winner           (winner),
        .player_hp        (player_hp),
        .cpu_hp           (cpu_hp),
        .player_action_reg(player_action_reg),
        .cpu_action_turn  (cpu_action_turn),
        .player_gain      (player_gain),
        .cpu_gain         (cpu_gain),
        .round_counter    (round_counter),
        .running          (running)
    );
endmodule
