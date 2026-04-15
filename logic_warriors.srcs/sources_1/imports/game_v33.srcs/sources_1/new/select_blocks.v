module priority_select4 #(
    parameter W = 4
)(
    input  wire [3:0]   req,
    input  wire [W-1:0] d0,
    input  wire [W-1:0] d1,
    input  wire [W-1:0] d2,
    input  wire [W-1:0] d3,
    output wire [W-1:0] y,
    output wire [3:0]   grant,
    output wire         valid
);
    wire [1:0] enc_unused;

    onehot_priority_encoder4 u_pri (.req(req), .grant(grant), .enc(enc_unused), .valid(valid));
    onehot_mux4_n #(.W(W)) u_mux (.d0(d0), .d1(d1), .d2(d2), .d3(d3), .sel(grant), .y(y));
endmodule

module popcount4 (
    input  wire [3:0] in,
    output wire [2:0] count
);
    wire [2:0] v0 = {2'b00, in[0]};
    wire [2:0] v1 = {2'b00, in[1]};
    wire [2:0] v2 = {2'b00, in[2]};
    wire [2:0] v3 = {2'b00, in[3]};
    wire [2:0] s01;
    wire [2:0] s23;

    cla_addsub #(.W(3)) u_add01 (.a(v0), .b(v1), .add_sub(1'b0), .sum(s01), .cout(), .overflow());
    cla_addsub #(.W(3)) u_add23 (.a(v2), .b(v3), .add_sub(1'b0), .sum(s23), .cout(), .overflow());
    cla_addsub #(.W(3)) u_addall (.a(s01), .b(s23), .add_sub(1'b0), .sum(count), .cout(), .overflow());
endmodule

module rotate_priority_select4 (
    input  wire [1:0] start_idx,
    input  wire [3:0] cand_mask,
    output wire [1:0] action,
    output wire       valid
);
    localparam [1:0] ACT_A = 2'd0;
    localparam [1:0] ACT_B = 2'd1;
    localparam [1:0] ACT_H = 2'd2;
    localparam [1:0] ACT_I = 2'd3;

    wire [1:0] act0, act1, act2, act3;
    wire [3:0] grant0, grant1, grant2, grant3;
    wire       valid0, valid1, valid2, valid3;
    wire [0:0] valid_mux;

    priority_select4 #(.W(2)) u_sel0 (
        .req   ({cand_mask[3], cand_mask[2], cand_mask[1], cand_mask[0]}),
        .d0    (ACT_A),
        .d1    (ACT_B),
        .d2    (ACT_H),
        .d3    (ACT_I),
        .y     (act0),
        .grant (grant0),
        .valid (valid0)
    );
    priority_select4 #(.W(2)) u_sel1 (
        .req   ({cand_mask[0], cand_mask[3], cand_mask[2], cand_mask[1]}),
        .d0    (ACT_B),
        .d1    (ACT_H),
        .d2    (ACT_I),
        .d3    (ACT_A),
        .y     (act1),
        .grant (grant1),
        .valid (valid1)
    );
    priority_select4 #(.W(2)) u_sel2 (
        .req   ({cand_mask[1], cand_mask[0], cand_mask[3], cand_mask[2]}),
        .d0    (ACT_H),
        .d1    (ACT_I),
        .d2    (ACT_A),
        .d3    (ACT_B),
        .y     (act2),
        .grant (grant2),
        .valid (valid2)
    );
    priority_select4 #(.W(2)) u_sel3 (
        .req   ({cand_mask[2], cand_mask[1], cand_mask[0], cand_mask[3]}),
        .d0    (ACT_I),
        .d1    (ACT_A),
        .d2    (ACT_B),
        .d3    (ACT_H),
        .y     (act3),
        .grant (grant3),
        .valid (valid3)
    );

    mux4_n #(.W(2)) u_act_mux (.d0(act0), .d1(act1), .d2(act2), .d3(act3), .sel(start_idx), .y(action));
    mux4_n #(.W(1)) u_val_mux (.d0(valid0), .d1(valid1), .d2(valid2), .d3(valid3), .sel(start_idx), .y(valid_mux));
    assign valid = valid_mux[0];
endmodule

module exclude_if_alternative4 (
    input  wire [3:0] cand_mask,
    input  wire [1:0] action,
    output wire [3:0] filtered_mask
);
    wire [3:0] action_oh;
    wire [2:0] cand_count;
    wire       count_gt1;
    wire [3:0] kill_mask;
    wire [3:0] keep_mask;

    decoder2to4 u_dec (.a(action), .y(action_oh));
    popcount4 u_pc (.in(cand_mask), .count(cand_count));
    gt_n #(.W(3), .SIGNED_MODE(0)) u_gt (.a(cand_count), .b(3'd1), .gt(count_gt1));
    mux2_n #(.W(4)) u_kill_mux (.d0(4'b0000), .d1(action_oh), .sel(count_gt1), .y(kill_mask));

    assign keep_mask = ~kill_mask;
    assign filtered_mask = cand_mask & keep_mask;
endmodule
