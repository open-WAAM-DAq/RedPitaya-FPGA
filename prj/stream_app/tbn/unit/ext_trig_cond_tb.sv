// Unit test of ext_trig_cond_250: simulated trigger level, synchronised level path, edge
// pulses, 16 bit debounce length, register read back. Self checking: prints PASS or FAIL.
`timescale 1ns / 1ps

module ext_trig_cond_tb;

logic        clk = 0, rstn = 0, trig_i = 0;
wire         trig_o;
logic [31:0] addr = 32'h68, wdata = 0;
logic        wen = 0, ren = 0;
wire  [31:0] rdata;
int          errors = 0;

always #2 clk = ~clk;

ext_trig_cond_250 dut (.clk(clk), .rstn(rstn), .trig_i(trig_i), .trig_o(trig_o),
  .sys_addr(addr), .sys_wdata(wdata), .sys_wen(wen), .sys_ren(ren), .sys_rdata(rdata), .sys_err(), .sys_ack());

task automatic wr(logic [31:0] v);
  @(negedge clk) begin wdata = v; wen = 1; end
  @(negedge clk) wen = 0;
endtask

task automatic check(bit ok, string what);
  if (!ok) begin errors++; $display("FAIL  %s (t=%0t)", what, $time); end
  else $display("ok    %s", what);
endtask

// number of clocks with trig_o high within n clocks
task automatic high_clocks(int n, output int cnt);
  cnt = 0;
  repeat (n) begin @(posedge clk); if (trig_o) cnt++; end
endtask

localparam COND = 1 << 0, FALL = 1 << 1, DEB = 1 << 2, SIM = 1 << 4, LVL = 1 << 5;
int cnt;

initial begin
  repeat (4) @(negedge clk);
  rstn = 1;
  repeat (4) @(negedge clk);

  // read back of every field
  wr(32'hABCD_0000 | LVL | SIM | DEB | FALL | COND);
  @(negedge clk);
  check(rdata == (32'hABCD_0000 | LVL | SIM | DEB | FALL | COND), $sformatf("register read back 0x%08X", rdata));

  // level path, simulated input: follows the level after the synchroniser
  wr(SIM);
  repeat (6) @(negedge clk);  // the previous level leaves the synchroniser
  high_clocks(20, cnt);
  check(cnt == 0, "simulated level low");
  wr(SIM | LVL);
  high_clocks(20, cnt);
  check(cnt >= 16, "level path follows the simulated level");
  trig_i = 1;
  wr(SIM);
  high_clocks(20, cnt);
  check(cnt <= 4, "simulation hides the pin");
  trig_i = 0;

  // conditioner: one clock pulse on the rising edge
  wr(COND | SIM);
  repeat (5) @(negedge clk);
  wr(COND | SIM | LVL);
  high_clocks(30, cnt);
  check(cnt == 1, $sformatf("rising edge: one pulse (%0d)", cnt));
  wr(COND | SIM);
  high_clocks(30, cnt);
  check(cnt == 0, "no pulse on the falling edge");

  // falling edge selected
  wr(COND | FALL | SIM | LVL);
  repeat (10) @(negedge clk);
  wr(COND | FALL | SIM);
  high_clocks(30, cnt);
  check(cnt == 1, $sformatf("falling edge: one pulse (%0d)", cnt));

  // debounce longer than 8 bit: 1000 clocks; a 400 clock glitch is ignored
  wr(32'd1000 << 16 | DEB | COND | SIM);
  repeat (1100) @(negedge clk);
  wr(32'd1000 << 16 | DEB | COND | SIM | LVL);
  repeat (400) @(negedge clk);
  wr(32'd1000 << 16 | DEB | COND | SIM);
  high_clocks(1200, cnt);
  // the debouncer takes the first change at once and then holds for the length
  check(cnt <= 1, $sformatf("debounce 1000: at most the first edge passes (%0d pulses)", cnt));
  wr(32'd1000 << 16 | DEB | COND | SIM | LVL);
  high_clocks(1200, cnt);
  wr(32'd1000 << 16 | DEB | COND | SIM);
  check(cnt == 1, "debounce 1000: a clean edge gives one pulse");

  // physical pin when the simulation is off
  wr(COND);
  trig_i = 1;
  high_clocks(20, cnt);
  check(cnt == 1, "pin edge with the simulation off");
  trig_i = 0;

  if (errors == 0) $display("PASS ext_trig_cond_tb");
  else $display("FAIL ext_trig_cond_tb: %0d checks", errors);
  $finish;
end

endmodule
