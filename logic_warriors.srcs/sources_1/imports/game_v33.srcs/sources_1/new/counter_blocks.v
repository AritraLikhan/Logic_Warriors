module sat_counter_n #(
    parameter W = 2,
    parameter MAX_VALUE = 3
)(
    input  wire         clk,
    input  wire         rst,
    input  wire         restart_pulse,
    input  wire         advance_pulse,
    output wire [W-1:0] count
);
    localparam [W-1:0] MAXV = MAX_VALUE;

    reg  [W-1:0] count_r;
    wire [W-1:0] count_inc;
    wire         at_max;

    inc_n #(.W(W)) u_inc (.a(count_r), .y(count_inc));
    ge_n  #(.W(W), .SIGNED_MODE(0)) u_ge (.a(count_r), .b(MAXV), .ge(at_max));

    assign count = count_r;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count_r <= {W{1'b0}};
        end else if (restart_pulse) begin
            count_r <= {W{1'b0}};
        end else if (advance_pulse && ~at_max) begin
            count_r <= count_inc;
        end
    end
endmodule

module history_valid_counter (
    input  wire clk,
    input  wire rst,
    input  wire restart_pulse,
    input  wire advance_pulse,
    output wire hist_ge_2,
    output wire hist_ge_3
);
    wire [1:0] history_depth;

    sat_counter_n #(.W(2), .MAX_VALUE(3)) u_hist_ctr (
        .clk          (clk),
        .rst          (rst),
        .restart_pulse(restart_pulse),
        .advance_pulse(advance_pulse),
        .count        (history_depth)
    );

    ge_n #(.W(2), .SIGNED_MODE(0)) u_ge2 (.a(history_depth), .b(2'd2), .ge(hist_ge_2));
    ge_n #(.W(2), .SIGNED_MODE(0)) u_ge3 (.a(history_depth), .b(2'd3), .ge(hist_ge_3));
endmodule
