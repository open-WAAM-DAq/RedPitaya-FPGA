////////////////////////////////////////////////////////////////////////////////
// LA capture into the S2MM side of the DMA, 250-12 (logic project).
//
// old_la_top (rtl_250) as in red_pitaya_top_250: 16 bit RLE stream at the ADC
// clock (250 MHz), its TREADY tied high (the LA cannot wait, see the top), then
// the stream path of the block design up to the S2MM input of axi_dma_2:
//   MODE 0  axis_dwidth_converter 16->64, axis_clock_converter 250->125 MHz,
//           axis_data_fifo 64 bit (the design since la_dma_wide)
//   MODE 1  axis_clock_converter 16 bit 250->250 MHz, axis_data_fifo 16 bit
//           (the design before, FCLK_CLK1 at 250 MHz)
//   MODE 2  axis_clock_converter 16 bit 250->125 MHz, axis_data_fifo 16 bit
//           (negative control: half the bandwidth, must lose data)
//   MODE 3  the 125 MS/s boards (Z10, Z20_14, G2, 4IN, LL) as built: LA at
//           125 MHz, axis_clock_converter 16 bit 125->125 MHz, FIFO 16 bit
//   MODE 4  the same widened: axis_dwidth_converter 16->32, 32 bit at 125 MHz
// The S2MM input is a sink at the DMA clock that drops TREADY between bursts,
// for a longer while every few thousand beats and at random (+stall=0: never).
//
// The input changes almost every sample (the worst case of RLE: one word per
// sample) with rare long runs (the 8 bit RLE count saturates). Checks:
//   - no cycle where the LA offers a word the path does not take (lost data)
//   - the unpacked capture equals the input sequence sample by sample
//   - the number of samples equals sts_pre + sts_pst, the last beat has TLAST
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module la_dma_tb #(
  int unsigned MODE = 0,
  int unsigned PRE  = 3000,
  int unsigned PST  = 120000
);

localparam realtime TA = (MODE >= 3) ? 8.0ns : 4.0ns; // ADC clock, 250 or 125 MHz
localparam realtime TF = (MODE == 1) ? 4.0ns : 8.0ns;  // DMA clock
localparam int unsigned MB = (MODE == 0) ? 8 : (MODE == 4) ? 4 : 2;  // bytes per DMA beat

logic aclk = 1'b0;
logic fclk = 1'b0;
logic rstn = 1'b0;
always #(TA/2) aclk = ~aclk;
always #(TF/2) fclk = ~fclk;

////////////////////////////////////////////////////////////////////////////////
// LA
////////////////////////////////////////////////////////////////////////////////

typedef logic [16-1:0] SBL_T;

axi4_stream_if #(.DT (SBL_T)) sti (.ACLK (aclk), .ARESETn (rstn));
axi4_stream_if #(.DT (SBL_T)) sto (.ACLK (aclk), .ARESETn (rstn));
sys_bus_if bus (.clk (aclk), .rstn (rstn));

logic [12-1:0] trg_ext;
logic          trg_swo;
logic          trg_out, irq_trg, irq_stp;
logic [64-1:0] cts = '0;

always @(posedge aclk) cts <= cts + 1;
assign trg_ext = {11'd0, trg_swo};

old_la_top #(
  .DT (SBL_T),
  .TN (12),
  .CW (32)
) la (
  .sti       (sti),
  .sto       (sto),
  .cts       (cts),
  .trg_ext   (trg_ext),
  .trg_swo   (trg_swo),
  .trg_out   (trg_out),
  .irq_trg   (irq_trg),
  .irq_stp   (irq_stp),
  .bus       (bus)
);

// as red_pitaya_top_250: the LA output is never held
assign sto.TREADY = 1'b1;

////////////////////////////////////////////////////////////////////////////////
// input: almost every sample new, rare long runs; every value is logged
////////////////////////////////////////////////////////////////////////////////

localparam int unsigned LOGN = 1 << 20;
logic [8-1:0] in_log [LOGN];
int unsigned  in_n = 0;
logic [8-1:0] in_val = 8'h00;
int unsigned  hold = 0;
int unsigned  seed = 1;

function automatic int unsigned rnd ();
  seed = seed * 1103515245 + 12345;
  return seed >> 8;
endfunction

assign sti.TDATA  = {8'h00, in_val};
assign sti.TKEEP  = '1;
assign sti.TLAST  = 1'b0;
assign sti.TVALID = 1'b1;

always @(posedge aclk) begin
  if (sti.transf && in_n < LOGN) begin
    in_log[in_n] <= in_val;
    in_n <= in_n + 1;
  end
  if (hold > 0) begin
    hold <= hold - 1;
  end else if (rnd() % 4096 == 0) begin
    hold <= 1 + rnd() % 400;                  // a long run: saturates the RLE count
  end else begin
    in_val <= in_val ^ (8'd1 + 8'(rnd() % 255)); // a different value
  end
end

////////////////////////////////////////////////////////////////////////////////
// block design stream path
////////////////////////////////////////////////////////////////////////////////

logic [8*MB-1:0] m_tdata;
logic [  MB-1:0] m_tkeep;
logic            m_tlast, m_tvalid, m_tready;
logic            s_tready;   // ready of the first IP, seen by the LA

generate
if (MODE == 0) begin: wide
  logic [64-1:0] w_tdata, c_tdata;
  logic [ 8-1:0] w_tkeep, c_tkeep;
  logic          w_tlast, w_tvalid, w_tready, c_tlast, c_tvalid, c_tready;
  la_dw16to64 dw (
    .aclk (aclk), .aresetn (rstn),
    .s_axis_tvalid (sto.TVALID), .s_axis_tready (s_tready), .s_axis_tdata (sto.TDATA),
    .s_axis_tkeep ({2{sto.TKEEP}}), .s_axis_tlast (sto.TLAST),
    .m_axis_tvalid (w_tvalid), .m_axis_tready (w_tready), .m_axis_tdata (w_tdata),
    .m_axis_tkeep (w_tkeep), .m_axis_tlast (w_tlast)
  );
  la_cc64 cc (
    .s_axis_aresetn (rstn), .m_axis_aresetn (rstn), .s_axis_aclk (aclk), .m_axis_aclk (fclk),
    .s_axis_tvalid (w_tvalid), .s_axis_tready (w_tready), .s_axis_tdata (w_tdata),
    .s_axis_tkeep (w_tkeep), .s_axis_tlast (w_tlast),
    .m_axis_tvalid (c_tvalid), .m_axis_tready (c_tready), .m_axis_tdata (c_tdata),
    .m_axis_tkeep (c_tkeep), .m_axis_tlast (c_tlast)
  );
  la_fifo64 ff (
    .s_axis_aresetn (rstn), .s_axis_aclk (fclk),
    .s_axis_tvalid (c_tvalid), .s_axis_tready (c_tready), .s_axis_tdata (c_tdata),
    .s_axis_tkeep (c_tkeep), .s_axis_tlast (c_tlast),
    .m_axis_tvalid (m_tvalid), .m_axis_tready (m_tready), .m_axis_tdata (m_tdata),
    .m_axis_tkeep (m_tkeep), .m_axis_tlast (m_tlast)
  );
end else if (MODE == 4) begin: wide32
  logic [32-1:0] w_tdata, c_tdata;
  logic [ 4-1:0] w_tkeep, c_tkeep;
  logic          w_tlast, w_tvalid, w_tready, c_tlast, c_tvalid, c_tready;
  la_dw16to32 dw (
    .aclk (aclk), .aresetn (rstn),
    .s_axis_tvalid (sto.TVALID), .s_axis_tready (s_tready), .s_axis_tdata (sto.TDATA),
    .s_axis_tkeep ({2{sto.TKEEP}}), .s_axis_tlast (sto.TLAST),
    .m_axis_tvalid (w_tvalid), .m_axis_tready (w_tready), .m_axis_tdata (w_tdata),
    .m_axis_tkeep (w_tkeep), .m_axis_tlast (w_tlast)
  );
  la_cc32 cc (
    .s_axis_aresetn (rstn), .m_axis_aresetn (rstn), .s_axis_aclk (aclk), .m_axis_aclk (fclk),
    .s_axis_tvalid (w_tvalid), .s_axis_tready (w_tready), .s_axis_tdata (w_tdata),
    .s_axis_tkeep (w_tkeep), .s_axis_tlast (w_tlast),
    .m_axis_tvalid (c_tvalid), .m_axis_tready (c_tready), .m_axis_tdata (c_tdata),
    .m_axis_tkeep (c_tkeep), .m_axis_tlast (c_tlast)
  );
  la_fifo32 ff (
    .s_axis_aresetn (rstn), .s_axis_aclk (fclk),
    .s_axis_tvalid (c_tvalid), .s_axis_tready (c_tready), .s_axis_tdata (c_tdata),
    .s_axis_tkeep (c_tkeep), .s_axis_tlast (c_tlast),
    .m_axis_tvalid (m_tvalid), .m_axis_tready (m_tready), .m_axis_tdata (m_tdata),
    .m_axis_tkeep (m_tkeep), .m_axis_tlast (m_tlast)
  );
end else begin: narrow
  logic [16-1:0] c_tdata;
  logic [ 2-1:0] c_tkeep;
  logic          c_tlast, c_tvalid, c_tready;
  la_cc16 cc (
    .s_axis_aresetn (rstn), .m_axis_aresetn (rstn), .s_axis_aclk (aclk), .m_axis_aclk (fclk),
    .s_axis_tvalid (sto.TVALID), .s_axis_tready (s_tready), .s_axis_tdata (sto.TDATA),
    .s_axis_tkeep ({2{sto.TKEEP}}), .s_axis_tlast (sto.TLAST),
    .m_axis_tvalid (c_tvalid), .m_axis_tready (c_tready), .m_axis_tdata (c_tdata),
    .m_axis_tkeep (c_tkeep), .m_axis_tlast (c_tlast)
  );
  la_fifo16 ff (
    .s_axis_aresetn (rstn), .s_axis_aclk (fclk),
    .s_axis_tvalid (c_tvalid), .s_axis_tready (c_tready), .s_axis_tdata (c_tdata),
    .s_axis_tkeep (c_tkeep), .s_axis_tlast (c_tlast),
    .m_axis_tvalid (m_tvalid), .m_axis_tready (m_tready), .m_axis_tdata (m_tdata),
    .m_axis_tkeep (m_tkeep), .m_axis_tlast (m_tlast)
  );
end
endgenerate

// a word the LA offers while the path is not ready is lost
int unsigned lost = 0;
always @(posedge aclk)
if (rstn && sto.TVALID && !s_tready)  lost <= lost + 1;

////////////////////////////////////////////////////////////////////////////////
// S2MM sink at the DMA clock
////////////////////////////////////////////////////////////////////////////////

bit          stall = 1;
int unsigned beats = 0;
int unsigned gap   = 0;
int unsigned fseed = 7;
logic [8-1:0] bytes [$];
bit          got_last = 0;
bit          last_ok  = 0;

function automatic int unsigned frnd ();
  fseed = fseed * 1103515245 + 12345;
  return fseed >> 8;
endfunction

always @(posedge fclk) begin
  if (!rstn) begin
    m_tready <= 1'b0;
  end else begin
    if (m_tvalid && m_tready) begin
      for (int b = 0; b < MB; b++)
        if (m_tkeep[b]) bytes.push_back(m_tdata[8*b +: 8]);
      beats <= beats + 1;
      if (m_tlast) begin got_last = 1; last_ok = 1; end
    end
    if (!stall) begin
      m_tready <= 1'b1;
    end else if (gap > 0) begin
      gap <= gap - 1;
      m_tready <= 1'b0;
    end else if (m_tvalid && m_tready && (beats % 4096) == 4095) begin
      gap <= 300;                 // descriptor / segment change
      m_tready <= 1'b0;
    end else if (m_tvalid && m_tready && (beats % 16) == 15) begin
      gap <= 1;                   // burst boundary
      m_tready <= 1'b0;
    end else begin
      m_tready <= (frnd() % 16) != 0;
    end
  end
end

////////////////////////////////////////////////////////////////////////////////
// bus
////////////////////////////////////////////////////////////////////////////////

task automatic bus_wr (input logic [32-1:0] a, input logic [32-1:0] d);
  @(posedge aclk);
  bus.addr <= a; bus.wdata <= d; bus.wen <= 1'b1;
  @(posedge aclk);
  bus.wen <= 1'b0;
  while (!bus.ack) @(posedge aclk);
endtask

task automatic bus_rd (input logic [32-1:0] a, output logic [32-1:0] d);
  @(posedge aclk);
  bus.addr <= a; bus.ren <= 1'b1;
  @(posedge aclk);
  bus.ren <= 1'b0;
  while (!bus.ack) @(posedge aclk);
  d = bus.rdata;
endtask

////////////////////////////////////////////////////////////////////////////////
// test
////////////////////////////////////////////////////////////////////////////////

int unsigned fails = 0;

task automatic check (input bit ok, input string msg);
  if (ok) $display("ok    %s", msg);
  else begin $display("FAIL  %s", msg); fails++; end
endtask

initial begin
  logic [32-1:0] sts_pre, sts_pst;
  int unsigned   nsmp, s0, words, cmp_err;
  logic [8-1:0]  smp [$];
  if ($test$plusargs("nostall")) stall = 0;
  bus.wen = 1'b0; bus.ren = 1'b0; bus.addr = '0; bus.wdata = '0;
  repeat (20) @(posedge aclk);
  rstn = 1'b1;
  repeat (20) @(posedge aclk);

  bus_wr('h00, 32'h1);        // reset
  bus_wr('h54, 32'h1);        // RLE on
  bus_wr('h50, 32'h0);        // decimation 1
  bus_wr('h10, PRE);
  bus_wr('h14, PST);
  bus_wr('h08, 32'h1);        // trigger: software
  bus_wr('h04, 32'h0);
  bus_wr('h00, 32'h4);        // start
  repeat (PRE + 1000) @(posedge aclk);
  bus_wr('h00, 32'h2);        // software trigger

  fork
    wait (got_last);
    begin #(TA * (PST * 4 + 200000)); end
  join_any
  disable fork;
  repeat (4000) @(posedge fclk);  // drain

  bus_rd('h18, sts_pre);
  bus_rd('h1c, sts_pst);

  // unpack: little endian 16 bit words {count, value}, count + 1 samples each
  words = bytes.size() / 2;
  for (int w = 0; w < words; w++) begin
    logic [8-1:0] v, c;
    v = bytes[2*w];
    c = bytes[2*w+1];
    for (int k = 0; k <= c; k++) smp.push_back(v);
  end
  nsmp = smp.size();

  $display("MODE %0d (%s), DMA stalls %s: %0d input samples, %0d RLE words, %0d samples unpacked, %0d DMA beats",
           MODE, MODE == 0 ? "LA 250 MHz, 16->64 bit, DMA 125 MHz" : MODE == 1 ? "LA 250 MHz, 16 bit, DMA 250 MHz" :
                 MODE == 2 ? "LA 250 MHz, 16 bit, DMA 125 MHz" : MODE == 3 ? "LA 125 MHz, 16 bit, DMA 125 MHz" :
                 "LA 125 MHz, 16->32 bit, DMA 125 MHz",
           stall ? "on" : "off", in_n, words, nsmp, beats);
  check(lost == 0, $sformatf("LA words lost at the path input: %0d", lost));
  check(got_last && last_ok, "last DMA beat has TLAST");
  // old_acq counts the trigger sample in both sts_pre and sts_pst
  check(nsmp == sts_pre + sts_pst - 1, $sformatf("samples %0d == sts_pre %0d + sts_pst %0d - 1", nsmp, sts_pre, sts_pst));

  // align the capture with the input log on its first 256 samples, then compare all
  s0 = '1;
  for (int s = 0; s + 256 < in_n && s < 10000; s++) begin
    bit eq = 1;
    for (int k = 0; k < 256 && eq; k++) eq = (in_log[s+k] == smp[k]);
    if (eq) begin s0 = s; break; end
  end
  check(s0 != '1, $sformatf("capture found in the input at sample %0d", s0));
  cmp_err = 0;
  if (s0 != '1)
    for (int k = 0; k < nsmp; k++)
      if (s0 + k >= in_n || in_log[s0+k] != smp[k]) begin
        if (cmp_err < 3) $display("      sample %0d: captured %02x, input %02x", k, smp[k], in_log[s0+k]);
        cmp_err++;
      end
  check(s0 != '1 && cmp_err == 0, $sformatf("captured samples equal to the input: %0d mismatches", cmp_err));

  if (fails == 0) $display("PASS la_dma_tb MODE %0d", MODE);
  else            $display("FAIL la_dma_tb MODE %0d (%0d checks)", MODE, fails);
  $finish;
end

endmodule: la_dma_tb
