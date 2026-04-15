

module tb_game_cu_fsm;
    reg clk;
    reg rst;
    reg btnc_pulse;
    reg btnl_pulse;
    reg btnr_pulse;
    reg btnu_pulse;
    reg btnd_pulse;

    wire [1:0] display_mode;
    wire winner;
    wire [3:0] player_hp;
    wire [3:0] cpu_hp;
    wire [1:0] player_action_reg;
    wire [1:0] cpu_action_turn;
    wire signed [3:0] player_gain;
    wire signed [3:0] cpu_gain;
    wire [7:0] round_counter;
    wire running;

    game_controller #(
        .CLK_HZ(100),
        .ACTION_VIEW_MS(5),
        .RESULT_VIEW_MS(5)
    ) dut (
        .clk(clk),
        .rst(rst),
        .btnc_pulse(btnc_pulse),
        .btnl_pulse(btnl_pulse),
        .btnr_pulse(btnr_pulse),
        .btnu_pulse(btnu_pulse),
        .btnd_pulse(btnd_pulse),
        .display_mode(display_mode),
        .winner(winner),
        .player_hp(player_hp),
        .cpu_hp(cpu_hp),
        .player_action_reg(player_action_reg),
        .cpu_action_turn(cpu_action_turn),
        .player_gain(player_gain),
        .cpu_gain(cpu_gain),
        .round_counter(round_counter),
        .running(running)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task pulse_center; begin btnc_pulse = 1; #10; btnc_pulse = 0; end endtask
    task pulse_left;   begin btnl_pulse = 1; #10; btnl_pulse = 0; end endtask
    task pulse_right;  begin btnr_pulse = 1; #10; btnr_pulse = 0; end endtask
    task pulse_up;     begin btnu_pulse = 1; #10; btnu_pulse = 0; end endtask
    task pulse_down;   begin btnd_pulse = 1; #10; btnd_pulse = 0; end endtask

    initial begin
        rst = 1;
        btnc_pulse = 0;
        btnl_pulse = 0;
        btnr_pulse = 0;
        btnu_pulse = 0;
        btnd_pulse = 0;
        #50;
        rst = 0;

        #20; pulse_center(); // start
        #40; pulse_left();   // attack
        #250; pulse_up();    // heal
        #250; pulse_right(); // block
        #250; pulse_down();  // idle
        #500;
        $finish;
    end
endmodule
