module cpu_ai_rules (
    input  wire              clk,
    input  wire              rst,
    input  wire              restart_pulse,
    input  wire              update_hist_pulse,
    input  wire [3:0]        player_hp,
    input  wire [3:0]        cpu_hp,
    input  wire [3:0]        player_hp_after_turn,
    input  wire [1:0]        player_action_reg,
    input  wire [1:0]        cpu_action_taken,
    input  wire signed [3:0] cpu_gain_this_turn,
    output reg  [1:0]        cpu_action_reg,
    output wire              player_repeat_penalty,
    output wire              cpu_repeat_penalty
);
    localparam [1:0] ACT_A = 2'd0;
    localparam [1:0] ACT_B = 2'd1;
    localparam [1:0] ACT_H = 2'd2;
    localparam [1:0] ACT_I = 2'd3;

    reg [1:0] P1, P2, P3;
    reg [1:0] C1, C2, C3;
    reg signed [3:0] D1, D2, D3;
    reg [3:0] player_hp_prev1, player_hp_prev2;
    reg [1:0] forced_block_counter;
    reg [2:0] cpu_turn_index;
    reg signed [5:0] score_a_r, score_b_r, score_h_r, score_i_r;
    reg signed [5:0] max_score_r;
    reg [3:0]        tie_mask_r;

    wire hist_ge_2;
    wire hist_ge_3;
    wire [5:0] score_a_next, score_b_next, score_h_next, score_i_next;
    wire [5:0] max_ab, max_abh, max_score_next;
    wire [3:0] tie_mask_next;
    wire [2:0] tied_count;
    wire [1:0] unique_action, tie_break_action, rotated_action;
    wire [3:0] cand_mask1, cand_mask2, cand_mask3;
    wire tie_break_valid, rotated_valid;
    wire tied_a, tied_b, tied_h, tied_i;
    wire tied_count_is1;
    wire cpu_turn_is0, cpu_turn_is1, cpu_turn_is2, cpu_turn_is7;
    wire forced_block_nonzero;
    wire hp_prev_lt;

    wire p1_isA, p1_isB, p1_isH, p1_isI;
    wire p2_isA, p2_isB, p2_isH, p2_isI;
    wire p3_isA, p3_isB;
    wire c1_isA, c1_isB, c1_isH, c1_isI;
    wire c2_isA, c2_isB, c2_isH;
    wire c3_isA, c3_isB;
    wire c_taken_isA, c_taken_isB, c_taken_isH, c_taken_eq_c1, c1_eq_c2;
    wire cpu_low, cpu_midlow, plr_low, player_pressing, cpu_trailing, cpu_ahead;
    wire d1_neg, d2_neg;

    wire p_attack2;
    wire p_attack3;
    wire p_heal2;
    wire p_block2;
    wire p_alt_ABA;
    wire p_alt_AHA;
    wire p_idle_last;
    wire p_heal_last;
    wire p_block_last;
    wire p_attack_last;
    wire player_passive2;
    wire c_repeat_non_attack;
    wire c_non_attack2;
    wire player_is_passive;
    wire player_repeat_a;
    wire player_repeat_h;
    wire player_repeat_b;
    wire cpu_repeat_a;
    wire cpu_repeat_h;
    wire cpu_repeat_b;
    wire trigger_forced_block;

    wire [5:0] sa_t0, sa_t1, sa_t2, sa_t3, sa_t4, sa_t5, sa_t6, sa_t7, sa_t8, sa_t9, sa_t10, sa_t11;
    wire [5:0] sb_t0, sb_t1, sb_t2, sb_t3, sb_t4, sb_t5, sb_t6;
    wire [5:0] sh_t0, sh_t1, sh_t2, sh_t3, sh_t4, sh_t5, sh_t6;
    wire [5:0] si_t0, si_t1, si_t2, si_t3, si_t4, si_t5;
    wire [5:0] sa_s1, sa_s2, sa_s3, sa_s4, sa_s5, sa_s6, sa_s7, sa_s8, sa_s9, sa_s10;
    wire [5:0] sb_s1, sb_s2, sb_s3, sb_s4, sb_s5;
    wire [5:0] sh_s1, sh_s2, sh_s3, sh_s4, sh_s5;
    wire [5:0] si_s1, si_s2, si_s3, si_s4;
    wire max_ab_sel, max_abh_sel, max_final_sel;
    wire req_choose_h, req_choose_b, req_choose_a, req_choose_i;
    wire [1:0] forced_block_dec;
    wire [2:0] cpu_turn_index_inc;

    history_valid_counter u_history_valid_counter (
        .clk          (clk),
        .rst          (rst),
        .restart_pulse(restart_pulse),
        .advance_pulse(update_hist_pulse),
        .hist_ge_2    (hist_ge_2),
        .hist_ge_3    (hist_ge_3)
    );

    eq_n #(.W(2), .SIGNED_MODE(0)) u_p1a (.a(P1), .b(ACT_A), .eq(p1_isA));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_p1b (.a(P1), .b(ACT_B), .eq(p1_isB));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_p1h (.a(P1), .b(ACT_H), .eq(p1_isH));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_p1i (.a(P1), .b(ACT_I), .eq(p1_isI));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_p2a (.a(P2), .b(ACT_A), .eq(p2_isA));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_p2b (.a(P2), .b(ACT_B), .eq(p2_isB));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_p2h (.a(P2), .b(ACT_H), .eq(p2_isH));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_p2i (.a(P2), .b(ACT_I), .eq(p2_isI));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_p3a (.a(P3), .b(ACT_A), .eq(p3_isA));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_p3b (.a(P3), .b(ACT_B), .eq(p3_isB));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_c1a (.a(C1), .b(ACT_A), .eq(c1_isA));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_c1b (.a(C1), .b(ACT_B), .eq(c1_isB));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_c1h (.a(C1), .b(ACT_H), .eq(c1_isH));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_c1i (.a(C1), .b(ACT_I), .eq(c1_isI));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_c2a (.a(C2), .b(ACT_A), .eq(c2_isA));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_c2b (.a(C2), .b(ACT_B), .eq(c2_isB));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_c2h (.a(C2), .b(ACT_H), .eq(c2_isH));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_c3a (.a(C3), .b(ACT_A), .eq(c3_isA));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_c3b (.a(C3), .b(ACT_B), .eq(c3_isB));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_cta (.a(cpu_action_taken), .b(ACT_A), .eq(c_taken_isA));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_ctb (.a(cpu_action_taken), .b(ACT_B), .eq(c_taken_isB));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_cth (.a(cpu_action_taken), .b(ACT_H), .eq(c_taken_isH));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_ctc1 (.a(cpu_action_taken), .b(C1), .eq(c_taken_eq_c1));
    eq_n #(.W(2), .SIGNED_MODE(0)) u_c1c2 (.a(C1), .b(C2), .eq(c1_eq_c2));

    le_n #(.W(4), .SIGNED_MODE(0)) u_cpu_low (.a(cpu_hp), .b(4'd2), .le(cpu_low));
    le_n #(.W(4), .SIGNED_MODE(0)) u_cpu_mid (.a(cpu_hp), .b(4'd4), .le(cpu_midlow));
    le_n #(.W(4), .SIGNED_MODE(0)) u_plr_low (.a(player_hp), .b(4'd2), .le(plr_low));
    ge_n #(.W(4), .SIGNED_MODE(0)) u_pressing (.a(player_hp), .b(cpu_hp), .ge(player_pressing));
    gt_n #(.W(4), .SIGNED_MODE(0)) u_trailing (.a(player_hp), .b(cpu_hp), .gt(cpu_trailing));
    gt_n #(.W(4), .SIGNED_MODE(0)) u_ahead (.a(cpu_hp), .b(player_hp), .gt(cpu_ahead));
    lt_n #(.W(4), .SIGNED_MODE(1)) u_d1neg (.a(D1), .b(4'sd0), .lt(d1_neg));
    lt_n #(.W(4), .SIGNED_MODE(1)) u_d2neg (.a(D2), .b(4'sd0), .lt(d2_neg));
    lt_n #(.W(4), .SIGNED_MODE(0)) u_hp_prev (.a(player_hp_prev2), .b(player_hp_prev1), .lt(hp_prev_lt));
    eq_n #(.W(3), .SIGNED_MODE(0)) u_turn0 (.a(cpu_turn_index), .b(3'd0), .eq(cpu_turn_is0));
    eq_n #(.W(3), .SIGNED_MODE(0)) u_turn1 (.a(cpu_turn_index), .b(3'd1), .eq(cpu_turn_is1));
    eq_n #(.W(3), .SIGNED_MODE(0)) u_turn2 (.a(cpu_turn_index), .b(3'd2), .eq(cpu_turn_is2));
    eq_n #(.W(3), .SIGNED_MODE(0)) u_turn7 (.a(cpu_turn_index), .b(3'd7), .eq(cpu_turn_is7));
    gt_n #(.W(2), .SIGNED_MODE(0)) u_fbc_nonzero (.a(forced_block_counter), .b(2'd0), .gt(forced_block_nonzero));

    assign p_attack2         = p1_isA & p2_isA;
    assign p_attack3         = p1_isA & p2_isA & p3_isA;
    assign p_heal2           = p1_isH & p2_isH;
    assign p_block2          = p1_isB & p2_isB;
    assign p_alt_ABA         = p3_isA & p2_isB & p1_isA;
    assign p_alt_AHA         = p3_isA & p2_isH & p1_isA;
    assign p_idle_last       = p1_isI;
    assign p_heal_last       = p1_isH;
    assign p_block_last      = p1_isB;
    assign p_attack_last     = p1_isA;
    assign player_passive2   = ~p1_isA & ~p2_isA;
    assign c_repeat_non_attack = ~c1_isA;
    assign c_non_attack2     = ~c1_isA & ~c2_isA;
    assign player_is_passive = p_heal2 | p_heal_last | player_passive2;
    assign player_repeat_a   = hist_ge_3 & p1_isA & p2_isA & p3_isA & (player_action_reg == ACT_A);
    assign player_repeat_h   = hist_ge_2 & p1_isH & p2_isH & (player_action_reg == ACT_H);
    assign player_repeat_b   = hist_ge_3 & p1_isB & p2_isB & p3_isB & (player_action_reg == ACT_B);
    assign cpu_repeat_a      = hist_ge_3 & c1_isA & c2_isA & c3_isA & c_taken_isA;
    assign cpu_repeat_h      = hist_ge_2 & c1_isH & c2_isH & c_taken_isH;
    assign cpu_repeat_b      = hist_ge_3 & c1_isB & c2_isB & c3_isB & c_taken_isB;
    assign trigger_forced_block = hist_ge_3 & ~c_taken_isB & c_taken_eq_c1 & c1_eq_c2 & cpu_gain_this_turn[3] & d1_neg & d2_neg;

    assign player_repeat_penalty = player_repeat_a | player_repeat_h | player_repeat_b;
    assign cpu_repeat_penalty    = cpu_repeat_a | cpu_repeat_h | cpu_repeat_b;

    assign sa_t0  = {6{cpu_trailing}}            & 6'sd4;
    assign sa_t1  = {6{p_heal2}}                 & 6'sd3;
    assign sa_t2  = {6{p_heal_last}}             & 6'sd2;
    assign sa_t3  = {6{p_idle_last}}             & 6'sd2;
    assign sa_t4  = {6{player_passive2}}         & 6'sd2;
    assign sa_t5  = {6{c_repeat_non_attack}}     & 6'sd2;
    assign sa_t6  = {6{p_block_last}}            & 6'sd1;
    assign sa_t7  = {6{p_alt_AHA}}               & 6'sd1;
    assign sa_t8  = {6{p_alt_ABA}}               & 6'sd1;
    assign sa_t9  = {6{plr_low}}                 & 6'sd1;
    assign sa_t10 = {6{c1_isA}}                  & -6'sd3;
    assign sa_t11 = {6{cpu_low}}                 & -6'sd2;

    assign sb_t0 = {6{p_attack3}}                        & 6'sd5;
    assign sb_t1 = {6{p_attack2}}                        & 6'sd3;
    assign sb_t2 = {6{p_alt_ABA}}                        & 6'sd2;
    assign sb_t3 = {6{player_pressing & (p1_isA | p2_isA)}} & 6'sd2;
    assign sb_t4 = {6{c1_isH & p_attack_last}}           & 6'sd1;
    assign sb_t5 = {6{c1_isB}}                           & -6'sd3;
    assign sb_t6 = {6{p_heal2}}                          & -6'sd1;

    assign sh_t0 = {6{cpu_low}}         & 6'sd6;
    assign sh_t1 = {6{cpu_midlow}}      & 6'sd3;
    assign sh_t2 = {6{p_block2}}        & 6'sd1;
    assign sh_t3 = {6{c1_isH}}          & -6'sd3;
    assign sh_t4 = {6{player_pressing}} & -6'sd3;
    assign sh_t5 = {6{p_attack2}}       & -6'sd2;
    assign sh_t6 = {6{cpu_trailing}}    & -6'sd1;

    assign si_t0 = {6{p_block2}}                 & 6'sd2;
    assign si_t1 = {6{p_heal_last & cpu_ahead}}  & 6'sd1;
    assign si_t2 = {6{p_idle_last}}              & 6'sd1;
    assign si_t3 = {6{player_pressing}}          & -6'sd3;
    assign si_t4 = {6{c1_isI}}                   & -6'sd2;
    assign si_t5 = {6{c_non_attack2}}            & -6'sd1;

    cla_addsub #(.W(6)) u_sa1  (.a(sa_t0),  .b(sa_t1),  .add_sub(1'b0), .sum(sa_s1),  .cout(), .overflow());
    cla_addsub #(.W(6)) u_sa2  (.a(sa_s1),  .b(sa_t2),  .add_sub(1'b0), .sum(sa_s2),  .cout(), .overflow());
    cla_addsub #(.W(6)) u_sa3  (.a(sa_s2),  .b(sa_t3),  .add_sub(1'b0), .sum(sa_s3),  .cout(), .overflow());
    cla_addsub #(.W(6)) u_sa4  (.a(sa_s3),  .b(sa_t4),  .add_sub(1'b0), .sum(sa_s4),  .cout(), .overflow());
    cla_addsub #(.W(6)) u_sa5  (.a(sa_s4),  .b(sa_t5),  .add_sub(1'b0), .sum(sa_s5),  .cout(), .overflow());
    cla_addsub #(.W(6)) u_sa6  (.a(sa_s5),  .b(sa_t6),  .add_sub(1'b0), .sum(sa_s6),  .cout(), .overflow());
    cla_addsub #(.W(6)) u_sa7  (.a(sa_s6),  .b(sa_t7),  .add_sub(1'b0), .sum(sa_s7),  .cout(), .overflow());
    cla_addsub #(.W(6)) u_sa8  (.a(sa_s7),  .b(sa_t8),  .add_sub(1'b0), .sum(sa_s8),  .cout(), .overflow());
    cla_addsub #(.W(6)) u_sa9  (.a(sa_s8),  .b(sa_t9),  .add_sub(1'b0), .sum(sa_s9),  .cout(), .overflow());
    cla_addsub #(.W(6)) u_sa10 (.a(sa_s9),  .b(sa_t10), .add_sub(1'b0), .sum(sa_s10), .cout(), .overflow());
    cla_addsub #(.W(6)) u_sa11 (.a(sa_s10), .b(sa_t11), .add_sub(1'b0), .sum(score_a_next), .cout(), .overflow());

    cla_addsub #(.W(6)) u_sb1 (.a(sb_t0), .b(sb_t1), .add_sub(1'b0), .sum(sb_s1), .cout(), .overflow());
    cla_addsub #(.W(6)) u_sb2 (.a(sb_s1), .b(sb_t2), .add_sub(1'b0), .sum(sb_s2), .cout(), .overflow());
    cla_addsub #(.W(6)) u_sb3 (.a(sb_s2), .b(sb_t3), .add_sub(1'b0), .sum(sb_s3), .cout(), .overflow());
    cla_addsub #(.W(6)) u_sb4 (.a(sb_s3), .b(sb_t4), .add_sub(1'b0), .sum(sb_s4), .cout(), .overflow());
    cla_addsub #(.W(6)) u_sb5 (.a(sb_s4), .b(sb_t5), .add_sub(1'b0), .sum(sb_s5), .cout(), .overflow());
    cla_addsub #(.W(6)) u_sb6 (.a(sb_s5), .b(sb_t6), .add_sub(1'b0), .sum(score_b_next), .cout(), .overflow());

    cla_addsub #(.W(6)) u_sh1 (.a(sh_t0), .b(sh_t1), .add_sub(1'b0), .sum(sh_s1), .cout(), .overflow());
    cla_addsub #(.W(6)) u_sh2 (.a(sh_s1), .b(sh_t2), .add_sub(1'b0), .sum(sh_s2), .cout(), .overflow());
    cla_addsub #(.W(6)) u_sh3 (.a(sh_s2), .b(sh_t3), .add_sub(1'b0), .sum(sh_s3), .cout(), .overflow());
    cla_addsub #(.W(6)) u_sh4 (.a(sh_s3), .b(sh_t4), .add_sub(1'b0), .sum(sh_s4), .cout(), .overflow());
    cla_addsub #(.W(6)) u_sh5 (.a(sh_s4), .b(sh_t5), .add_sub(1'b0), .sum(sh_s5), .cout(), .overflow());
    cla_addsub #(.W(6)) u_sh6 (.a(sh_s5), .b(sh_t6), .add_sub(1'b0), .sum(score_h_next), .cout(), .overflow());

    cla_addsub #(.W(6)) u_si1 (.a(si_t0), .b(si_t1), .add_sub(1'b0), .sum(si_s1), .cout(), .overflow());
    cla_addsub #(.W(6)) u_si2 (.a(si_s1), .b(si_t2), .add_sub(1'b0), .sum(si_s2), .cout(), .overflow());
    cla_addsub #(.W(6)) u_si3 (.a(si_s2), .b(si_t3), .add_sub(1'b0), .sum(si_s3), .cout(), .overflow());
    cla_addsub #(.W(6)) u_si4 (.a(si_s3), .b(si_t4), .add_sub(1'b0), .sum(si_s4), .cout(), .overflow());
    cla_addsub #(.W(6)) u_si5 (.a(si_s4), .b(si_t5), .add_sub(1'b0), .sum(score_i_next), .cout(), .overflow());

    gt_n #(.W(6), .SIGNED_MODE(1)) u_maxab_gt (.a(score_a_next), .b(score_b_next), .gt(max_ab_sel));
    mux2_n #(.W(6)) u_maxab_mux (.d0(score_b_next), .d1(score_a_next), .sel(max_ab_sel), .y(max_ab));
    gt_n #(.W(6), .SIGNED_MODE(1)) u_maxabh_gt (.a(max_ab), .b(score_h_next), .gt(max_abh_sel));
    mux2_n #(.W(6)) u_maxabh_mux (.d0(score_h_next), .d1(max_ab), .sel(max_abh_sel), .y(max_abh));
    gt_n #(.W(6), .SIGNED_MODE(1)) u_maxfin_gt (.a(max_abh), .b(score_i_next), .gt(max_final_sel));
    mux2_n #(.W(6)) u_maxfin_mux (.d0(score_i_next), .d1(max_abh), .sel(max_final_sel), .y(max_score_next));

    eq_n #(.W(6), .SIGNED_MODE(1)) u_tiea (.a(score_a_next), .b(max_score_next), .eq(tie_mask_next[0]));
    eq_n #(.W(6), .SIGNED_MODE(1)) u_tieb (.a(score_b_next), .b(max_score_next), .eq(tie_mask_next[1]));
    eq_n #(.W(6), .SIGNED_MODE(1)) u_tieh (.a(score_h_next), .b(max_score_next), .eq(tie_mask_next[2]));
    eq_n #(.W(6), .SIGNED_MODE(1)) u_tiei (.a(score_i_next), .b(max_score_next), .eq(tie_mask_next[3]));

    assign tied_a = tie_mask_r[0] & (score_a_r == max_score_r);
    assign tied_b = tie_mask_r[1] & (score_b_r == max_score_r);
    assign tied_h = tie_mask_r[2] & (score_h_r == max_score_r);
    assign tied_i = tie_mask_r[3] & (score_i_r == max_score_r);

    popcount4 u_tied_count (.in({tied_i, tied_h, tied_b, tied_a}), .count(tied_count));
    eq_n #(.W(3), .SIGNED_MODE(0)) u_tie_is1 (.a(tied_count), .b(3'd1), .eq(tied_count_is1));
    onehot_mux4_n #(.W(2)) u_unique_act (
        .d0  (ACT_A),
        .d1  (ACT_B),
        .d2  (ACT_H),
        .d3  (ACT_I),
        .sel ({tied_i, tied_h, tied_b, tied_a}),
        .y   (unique_action)
    );

    assign req_choose_h = cpu_low & tied_h;
    assign req_choose_b = p_attack2 & tied_b;
    assign req_choose_a = (player_is_passive & tied_a) | (p_block2 & tied_a);
    assign req_choose_i = p_block2 & tied_i & ~player_pressing;

    priority_select4 #(.W(2)) u_tiebreak (
        .req   ({req_choose_i, req_choose_a, req_choose_b, req_choose_h}),
        .d0    (ACT_H),
        .d1    (ACT_B),
        .d2    (ACT_A),
        .d3    (ACT_I),
        .y     (tie_break_action),
        .grant (),
        .valid (tie_break_valid)
    );

    exclude_if_alternative4 u_excl0 (.cand_mask({tied_i, tied_h, tied_b, tied_a}), .action(C1), .filtered_mask(cand_mask1));
    exclude_if_alternative4 u_excl1 (.cand_mask(cand_mask1), .action(C2), .filtered_mask(cand_mask2));
    exclude_if_alternative4 u_excl2 (.cand_mask(cand_mask2), .action(C3), .filtered_mask(cand_mask3));
    rotate_priority_select4 u_rotate (.start_idx(cpu_turn_index[1:0]), .cand_mask(cand_mask3), .action(rotated_action), .valid(rotated_valid));

    dec_n #(.W(2)) u_fbc_dec (.a(forced_block_counter), .y(forced_block_dec[1:0]));
    inc_n #(.W(3)) u_turn_inc (.a(cpu_turn_index), .y(cpu_turn_index_inc));

    always @(*) begin
        cpu_action_reg = ACT_A;

        if (forced_block_nonzero) begin
            cpu_action_reg = ACT_B;
        end else if (cpu_turn_is0) begin
            cpu_action_reg = ACT_B;
        end else if (cpu_turn_is1) begin
            cpu_action_reg = ACT_A;
        end else if (cpu_turn_is2) begin
            if (hp_prev_lt)
                cpu_action_reg = ACT_A;
            else
                cpu_action_reg = ACT_B;
        end else if (tied_count_is1) begin
            cpu_action_reg = unique_action;
        end else if (tie_break_valid) begin
            cpu_action_reg = tie_break_action;
        end else if (rotated_valid) begin
            cpu_action_reg = rotated_action;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            P1 <= ACT_I;
            P2 <= ACT_I;
            P3 <= ACT_I;
            C1 <= ACT_B;
            C2 <= ACT_B;
            C3 <= ACT_B;
            D1 <= 4'sd0;
            D2 <= 4'sd0;
            D3 <= 4'sd0;
            player_hp_prev1 <= 4'd9;
            player_hp_prev2 <= 4'd9;
            forced_block_counter <= 2'd0;
            cpu_turn_index <= 3'd0;
            score_a_r <= 6'sd0;
            score_b_r <= 6'sd0;
            score_h_r <= 6'sd0;
            score_i_r <= 6'sd0;
            max_score_r <= 6'sd0;
            tie_mask_r <= 4'b0001;
        end else if (restart_pulse) begin
            P1 <= ACT_I;
            P2 <= ACT_I;
            P3 <= ACT_I;
            C1 <= ACT_B;
            C2 <= ACT_B;
            C3 <= ACT_B;
            D1 <= 4'sd0;
            D2 <= 4'sd0;
            D3 <= 4'sd0;
            player_hp_prev1 <= 4'd9;
            player_hp_prev2 <= 4'd9;
            forced_block_counter <= 2'd0;
            cpu_turn_index <= 3'd0;
            score_a_r <= 6'sd0;
            score_b_r <= 6'sd0;
            score_h_r <= 6'sd0;
            score_i_r <= 6'sd0;
            max_score_r <= 6'sd0;
            tie_mask_r <= 4'b0001;
        end else if (update_hist_pulse) begin
            P3 <= P2;
            P2 <= P1;
            P1 <= player_action_reg;
            C3 <= C2;
            C2 <= C1;
            C1 <= cpu_action_taken;
            D3 <= D2;
            D2 <= D1;
            D1 <= cpu_gain_this_turn;
            player_hp_prev2 <= player_hp_prev1;
            player_hp_prev1 <= player_hp_after_turn;

            if (trigger_forced_block)
                forced_block_counter <= 2'd2;
            else if (forced_block_nonzero)
                forced_block_counter <= forced_block_dec[1:0];

            if (~cpu_turn_is7)
                cpu_turn_index <= cpu_turn_index_inc;

            score_a_r <= score_a_next;
            score_b_r <= score_b_next;
            score_h_r <= score_h_next;
            score_i_r <= score_i_next;
            max_score_r <= max_score_next;
            tie_mask_r <= tie_mask_next;
        end else begin
            score_a_r <= score_a_next;
            score_b_r <= score_b_next;
            score_h_r <= score_h_next;
            score_i_r <= score_i_next;
            max_score_r <= max_score_next;
            tie_mask_r <= tie_mask_next;
        end
    end
endmodule
