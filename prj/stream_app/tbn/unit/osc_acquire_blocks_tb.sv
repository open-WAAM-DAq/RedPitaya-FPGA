// Unit test of the block mode of osc_acquire: N blocks per trigger, a trigger inside a series
// writes the current block and N more (trigger in block k -> the series ends with block k+N),
// re-arming after the series, the drop strobe for the samples not written while waiting.
// Self checking: prints PASS or FAIL.
`timescale 1ns / 1ps

module osc_acquire_blocks_tb;

localparam int SPB = 16;  // samples per block

logic        clk = 0, rst_n = 0;
logic [15:0] s_tdata = 0;
logic        s_tvalid = 1;
wire  [15:0] m_tdata;
wire         m_tvalid, m_tlast;
logic        ctl_start = 0, ctl_rst = 0, ctl_stop = 0, ctl_trig = 0;
logic [15:0] blocks = 4;
wire         armed, accepted, drop;
int          errors = 0;

always #4 clk = ~clk;
always @(posedge clk) s_tdata <= s_tdata + 1;

osc_acquire dut (
  .clk(clk), .rst_n(rst_n),
  .s_axis_tdata(s_tdata), .s_axis_tvalid(s_tvalid), .s_axis_tready(),
  .m_axis_tdata(m_tdata), .m_axis_tvalid(m_tvalid), .m_axis_tready(1'b1), .m_axis_tlast(m_tlast),
  .ctl_start(ctl_start), .ctl_rst(ctl_rst), .ctl_stop(ctl_stop), .ctl_trig(ctl_trig),
  .cfg_trigger_mode(1'b1), .cfg_trig_blocks(blocks), .cfg_block_samples(32'(SPB)),
  .cfg_mode(1'b1), .cfg_trig_pre_samp(32'd0), .cfg_trig_post_samp(32'd0),
  .sts_start(), .sts_stop(), .sts_trig(),
  .sts_trig_pre_cnt(), .sts_trig_pre_overflow(), .sts_trig_post_cnt(), .sts_trig_post_overflow(),
  .sts_armed(armed), .accepted_trigger(accepted), .sts_drop(drop));

// counts the written samples and the dropped ones
int written = 0, dropped = 0;
always @(posedge clk) begin
  if (m_tvalid) written <= written + 1;
  if (drop) dropped <= dropped + 1;
end

// samples dropped between the first and the second series of a run
int d_end = -1, d_start = -1;
always @(posedge clk) begin
  if (written == 4 * SPB && d_end < 0) d_end = dropped;
  if (written == 4 * SPB + 1 && d_start < 0) d_start = dropped;
end

task automatic pulse(ref logic sig);
  @(negedge clk) sig = 1;
  @(negedge clk) sig = 0;
endtask

task automatic idle(int n);
  repeat (n) @(negedge clk);
endtask

task automatic check(bit ok, string what);
  if (!ok) begin errors++; $display("FAIL  %s (t=%0t)", what, $time); end
  else $display("ok    %s", what);
endtask

// waits until the core is armed again (or n clocks)
task automatic wait_armed(int n);
  for (int i = 0; i < n && !armed; i++) @(negedge clk);
  idle(2);  // the counters of this bench see the last output sample a clock later
endtask

task automatic restart();
  pulse(ctl_stop);
  idle(3);
  written = 0;
  dropped = 0;
endtask

initial begin
  idle(5);
  rst_n = 1;
  idle(5);

  // one trigger: exactly N blocks, then armed again
  pulse(ctl_start);
  idle(2);
  written = 0;
  pulse(ctl_trig);
  wait_armed(10 * SPB);
  check(armed, "re-armed after the series");
  check(written == 4 * SPB, $sformatf("one trigger: 4 blocks = %0d samples (%0d)", 4 * SPB, written));
  idle(3 * SPB);
  check(written == 4 * SPB, "nothing written while waiting again");
  check(dropped >= 3 * SPB, $sformatf("samples while waiting are dropped (%0d)", dropped));
  restart();

  // trigger in block 2 -> 6 blocks; trigger in block 4 -> 8 blocks
  pulse(ctl_start);
  idle(2);
  written = 0;
  pulse(ctl_trig);
  idle(SPB + SPB / 2 - 2);   // inside block 2
  pulse(ctl_trig);
  idle(2 * SPB);             // inside block 4
  pulse(ctl_trig);
  wait_armed(20 * SPB);
  check(written == 8 * SPB, $sformatf("triggers in blocks 1, 2 and 4: 8 blocks (%0d samples, %0d expected)", written, 8 * SPB));
  restart();

  // a trigger on the last sample of the series extends it, one after the series starts a new one
  pulse(ctl_start);
  idle(2);
  written = 0;
  pulse(ctl_trig);
  wait_armed(10 * SPB);
  dropped = 0;
  idle(SPB / 2);
  pulse(ctl_trig);
  wait_armed(10 * SPB);
  check(written == 8 * SPB, $sformatf("a second series after a pause: 4 + 4 blocks (%0d)", written));
  check(dropped >= SPB / 2 && dropped <= SPB / 2 + 4, $sformatf("drops between the series = the pause (%0d)", dropped));
  restart();

  // a trigger around the last sample of a series is never lost: the series goes on (at most
  // one sample is dropped and counted when it lands on the very last one)
  for (int off = 3; off >= -2; off--) begin
    pulse(ctl_start);
    idle(2);
    written = 0;
    dropped = 0;
    pulse(ctl_trig);
    idle(2);
    d_end = -1;
    d_start = -1;
    while (written < 4 * SPB - 2 - off) @(negedge clk);
    pulse(ctl_trig);
    // the core is armed for one clock between the two series: wait for the second one
    for (int i = 0; i < 20 * SPB && written < 8 * SPB; i++) @(negedge clk);
    wait_armed(20 * SPB);
    // between the series: nothing dropped when the trigger extends the series, one sample when
    // it lands on the last one, and those up to a trigger after the end
    check(armed && written == 8 * SPB && (d_start - d_end) <= (off >= 2 ? 0 : 2 - off),
          $sformatf("trigger %0d samples before the series end: %0d written (%0d), %0d dropped between the series", off, written, 8 * SPB,
                    d_start - d_end));
    restart();
  end

  // N = 1
  blocks = 1;
  pulse(ctl_start);
  idle(2);
  written = 0;
  pulse(ctl_trig);
  wait_armed(10 * SPB);
  check(written == SPB, $sformatf("N = 1: one block (%0d)", written));
  restart();

  // N = 0: continuous after the trigger, as before
  blocks = 0;
  pulse(ctl_start);
  idle(2);
  written = 0;
  pulse(ctl_trig);
  idle(10 * SPB);
  check(!armed && written >= 10 * SPB - 2, $sformatf("N = 0: continuous (%0d)", written));
  restart();

  // stop inside a series
  blocks = 4;
  pulse(ctl_start);
  idle(2);
  pulse(ctl_trig);
  idle(SPB);
  pulse(ctl_stop);
  idle(2);
  written = 0;
  idle(5 * SPB);
  check(written == 0 && !armed, "stop inside a series ends it");

  if (errors == 0) $display("PASS osc_acquire_blocks_tb");
  else $display("FAIL osc_acquire_blocks_tb: %0d checks", errors);
  $finish;
end

endmodule
