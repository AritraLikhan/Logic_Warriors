module debounce_edge #(
    parameter integer CNTR_BITS = 20
)(
    input  wire clk,
    input  wire rst,
    input  wire din,
    output reg  level,
    output reg  pulse
);
    reg sync0, sync1;
    reg [CNTR_BITS-1:0] cnt;
    wire [CNTR_BITS-1:0] cnt_inc;
    wire cnt_full;
    wire sync_matches_level;

    inc_n        #(.W(CNTR_BITS))          u_cnt_inc (.a(cnt), .y(cnt_inc));
    reduce_and_n #(.W(CNTR_BITS))          u_cnt_and (.din(cnt), .dout(cnt_full));
    eq_n         #(.W(1), .SIGNED_MODE(0)) u_sync_eq (.a(sync1), .b(level), .eq(sync_matches_level));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync0 <= 1'b0;
            sync1 <= 1'b0;
            cnt   <= {CNTR_BITS{1'b0}};
            level <= 1'b0;
            pulse <= 1'b0;
        end else begin
            sync0 <= din;
            sync1 <= sync0;
            pulse <= 1'b0;

            if (sync_matches_level) begin
                cnt <= {CNTR_BITS{1'b0}};
            end else begin
                cnt <= cnt_inc;
                if (cnt_full) begin
                    level <= sync1;
                    cnt   <= {CNTR_BITS{1'b0}};
                    if (sync1)
                        pulse <= 1'b1;
                end
            end
        end
    end
endmodule
