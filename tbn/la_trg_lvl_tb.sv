////////////////////////////////////////////////////////////////////////////////
// Module: la_trg with and without LEVEL_ONLY, self-checking
// (c) Red Pitaya  (redpitaya.com)
//
// xvlog -sv rtl/rtl/interface/axi4_stream_if.sv rtl/rtl/axi4_stream_reg.sv \
//           rtl/rtl/la_trg.sv tbn/la_trg_lvl_tb.sv
// xelab -timescale 1ns/1ps la_trg_lvl_tb -s tb && xsim tb -R
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
module la_trg_lvl_tb;
typedef logic [8-1:0] DT;
logic clk = 0, rstn = 0;
always #2 clk = ~clk;

DT msk, val, pos, neg;
logic [1-1:0] trg0, trg1;
DT din;
int errors = 0;

axi4_stream_if #(.DN (1), .DT (DT)) si0 (.ACLK (clk), .ARESETn (rstn));
axi4_stream_if #(.DN (1), .DT (DT)) so0 (.ACLK (clk), .ARESETn (rstn));
axi4_stream_if #(.DN (1), .DT (DT)) si1 (.ACLK (clk), .ARESETn (rstn));
axi4_stream_if #(.DN (1), .DT (DT)) so1 (.ACLK (clk), .ARESETn (rstn));
for (genvar k = 0; k < 1; k++) begin
  assign si0.TDATA[k] = din;  assign si1.TDATA[k] = din;
end
assign si0.TKEEP = '1; assign si0.TLAST = 0; assign si0.TVALID = 1; assign so0.TREADY = 1;
assign si1.TKEEP = '1; assign si1.TLAST = 0; assign si1.TVALID = 1; assign so1.TREADY = 1;

la_trg #(.DT (DT), .LEVEL_ONLY (0)) dut0 (.ctl_rst (1'b0), .cfg_cmp_msk (msk), .cfg_cmp_val (val), .cfg_edg_pos (pos), .cfg_edg_neg (neg), .sts_trg (trg0), .sti (si0), .sto (so0));
la_trg #(.DT (DT), .LEVEL_ONLY (1)) dut1 (.ctl_rst (1'b0), .cfg_cmp_msk (msk), .cfg_cmp_val (val), .cfg_edg_pos (pos), .cfg_edg_neg (neg), .sts_trg (trg1), .sti (si1), .sto (so1));

// count triggers of both instances over a data sequence
task automatic run (string name, DT m, DT v, DT p, DT n, DT seq [], int exp0, int exp1);
  int c0 = 0, c1 = 0;
  msk = m; val = v; pos = p; neg = n;
  din = seq[0];
  repeat (3) @(posedge clk);
  foreach (seq[i]) begin
    din <= seq[i];
    @(posedge clk);
    #0.1; c0 += trg0; c1 += trg1;
  end
  repeat (3) begin @(posedge clk); #0.1; c0 += trg0; c1 += trg1; end
  if (c0 != exp0 || c1 != exp1) begin
    errors++;
    $display("FAIL %s: LEVEL_ONLY=0 %0d (exp %0d), LEVEL_ONLY=1 %0d (exp %0d)", name, c0, exp0, c1, exp1);
  end else
    $display("ok   %s: %0d / %0d", name, c0, c1);
endtask

initial begin
  DT s [];
  msk = 0; val = 0; pos = 0; neg = 0; din = 0;
  repeat (4) @(posedge clk); rstn = 1;
  // bit0: 0 0 1 1 1 0 0 1 0 ; bit1 high during the second pulse only
  s = '{8'h00, 8'h00, 8'h01, 8'h01, 8'h01, 8'h00, 8'h00, 8'h03, 8'h02, 8'h00};
  // trailing 3 cycles repeat the last value (0x00) and count too
  run ("nothing configured",          8'h00, 8'h00, 8'h00, 8'h00, s, 0, 0);
  run ("level bit0 high, no edge",    8'h01, 8'h01, 8'h00, 8'h00, s, 0, 4);
  run ("level bit0 low, no edge",     8'h01, 8'h00, 8'h00, 8'h00, s, 0, 6 + 3);
  run ("rising bit0",                 8'h00, 8'h00, 8'h01, 8'h00, s, 2, 2);
  run ("falling bit0",                8'h00, 8'h00, 8'h00, 8'h01, s, 2, 2);
  run ("either bit0",                 8'h00, 8'h00, 8'h01, 8'h01, s, 4, 4);
  run ("rising bit0 and bit1 high",   8'h02, 8'h02, 8'h01, 8'h00, s, 1, 1);
  run ("rising bit0 and bit1 low",    8'h02, 8'h00, 8'h01, 8'h00, s, 1, 1);
  run ("pattern bit0..1 = 11, level", 8'h03, 8'h03, 8'h00, 8'h00, s, 0, 1);
  $display("RESULT %s (%0d errors)", errors ? "FAIL" : "PASS", errors);
  $finish;
end
endmodule
