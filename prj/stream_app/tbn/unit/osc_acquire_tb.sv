// Unit test of osc_acquire in streaming: trigger mode, edge acceptance, clearing the mode while
// armed, stop while armed, and the unchanged mode 0. Self checking: prints PASS or FAIL.
`timescale 1ns / 1ps

module osc_acquire_tb;

logic        clk = 0, rst_n = 0;
logic [15:0] s_tdata = 0;
logic        s_tvalid = 1;
wire  [15:0] m_tdata;
wire         m_tvalid, m_tlast;
logic        ctl_start = 0, ctl_rst = 0, ctl_stop = 0, ctl_trig = 0, trig_mode = 0;
logic        cfg_mode = 1;  // streaming
wire         sts_start, sts_stop, sts_trig, sts_pre_ovf, sts_post_ovf, armed, accepted;
wire  [31:0] sts_pre, sts_post;
int          errors = 0;

always #4 clk = ~clk;
always @(posedge clk) s_tdata <= s_tdata + 1;

osc_acquire dut (
  .clk(clk), .rst_n(rst_n),
  .s_axis_tdata(s_tdata), .s_axis_tvalid(s_tvalid), .s_axis_tready(),
  .m_axis_tdata(m_tdata), .m_axis_tvalid(m_tvalid), .m_axis_tready(1'b1), .m_axis_tlast(m_tlast),
  .ctl_start(ctl_start), .ctl_rst(ctl_rst), .ctl_stop(ctl_stop), .ctl_trig(ctl_trig),
  .cfg_trigger_mode(trig_mode), .cfg_trig_blocks(16'd0), .cfg_block_samples(32'd64), .cfg_mode(cfg_mode),
  .cfg_trig_pre_samp(32'd4), .cfg_trig_post_samp(32'd4),
  .sts_start(sts_start), .sts_stop(sts_stop), .sts_trig(sts_trig),
  .sts_trig_pre_cnt(sts_pre), .sts_trig_pre_overflow(sts_pre_ovf),
  .sts_trig_post_cnt(sts_post), .sts_trig_post_overflow(sts_post_ovf),
  .sts_armed(armed), .accepted_trigger(accepted), .sts_drop());

task automatic pulse(ref logic sig, input int n = 1);
  @(negedge clk) sig = 1;
  repeat (n) @(negedge clk);
  sig = 0;
endtask

task automatic idle(int n);
  repeat (n) @(negedge clk);
endtask

task automatic check(bit ok, string what);
  if (!ok) begin
    errors++;
    $display("FAIL  %s (t=%0t)", what, $time);
  end else
    $display("ok    %s", what);
endtask

// counts output samples over n clocks
task automatic count_valid(int n, output int cnt);
  cnt = 0;
  repeat (n) begin
    @(posedge clk);
    if (m_tvalid) cnt++;
  end
endtask

task automatic restart();
  pulse(ctl_stop);
  idle(3);
endtask

int cnt;

initial begin
  idle(5);
  rst_n = 1;
  idle(5);

  // mode 0: data from the start
  trig_mode = 0;
  pulse(ctl_start);
  count_valid(20, cnt);
  check(cnt >= 18, "mode 0 streams from the start");
  check(!armed, "mode 0 never armed");
  restart();

  // trigger mode: armed, nothing written until the edge
  trig_mode = 1;
  pulse(ctl_start);
  idle(2);
  check(armed, "trigger mode armed after the start");
  count_valid(50, cnt);
  check(cnt == 0, "nothing written while armed");
  pulse(ctl_trig);
  idle(1);
  check(!armed, "armed cleared by the trigger");
  count_valid(20, cnt);
  check(cnt >= 18, "the trigger starts the writing");
  pulse(ctl_trig);
  count_valid(20, cnt);
  check(cnt >= 18, "further triggers change nothing");
  restart();

  // a trigger that is high before the core arms waits for its next edge (as the DAC does)
  @(negedge clk) ctl_trig = 1;
  pulse(ctl_start);
  idle(2);
  check(armed, "trigger already high: armed");
  count_valid(50, cnt);
  check(cnt == 0, "trigger already high: nothing written");
  @(negedge clk) ctl_trig = 0;
  idle(2);
  check(armed, "still armed after the trigger fell");
  pulse(ctl_trig);
  count_valid(20, cnt);
  check(cnt >= 18, "the next edge starts the writing");
  restart();

  // a trigger before the start is not latched
  pulse(ctl_trig);
  idle(2);
  pulse(ctl_start);
  idle(2);
  count_valid(30, cnt);
  check(armed && cnt == 0, "trigger before the start ignored");
  restart();

  // stop while armed returns to idle
  pulse(ctl_start);
  idle(3);
  pulse(ctl_stop);
  idle(2);
  check(!armed, "stop while armed clears armed");
  count_valid(20, cnt);
  check(cnt == 0, "nothing written after the stop");

  // clearing the trigger mode while armed starts the writing instead of hanging
  pulse(ctl_start);
  idle(3);
  @(negedge clk) trig_mode = 0;
  idle(2);
  count_valid(20, cnt);
  check(cnt >= 18, "trigger mode cleared while armed: writing starts");
  restart();
  trig_mode = 1;

  if (errors == 0) $display("PASS osc_acquire_tb");
  else $display("FAIL osc_acquire_tb: %0d checks", errors);
  $finish;
end

endmodule
