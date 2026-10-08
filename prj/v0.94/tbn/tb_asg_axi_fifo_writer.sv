`timescale 1ns / 1ps

module tb_asg_axi_fifo_writer;

logic clk = 1'b0;
logic rstn = 1'b0;
logic start_pulse = 1'b0;
logic set_rst = 1'b0;
logic [31:0] start_addr = '0;
logic [31:0] stop_addr = '0;
logic fifo_full = 1'b0;
logic [6:0] fifo_level = '0;
logic fifo_rst_busy = 1'b0;
logic arready = 1'b0;
logic rvalid = 1'b0;
logic rlast = 1'b0;
logic [63:0] rdata = '0;

logic [63:0] fifo_data;
logic fifo_wr;
logic axi_fifo_reset;

always #2 clk = ~clk;

axi_sys_if axi (
  .clk  (clk),
  .rstn (rstn)
);

assign axi.rardy = arready;
assign axi.rrdym = rvalid;
assign axi.rlast = rlast;
assign axi.rdata = rdata;

rp_asg_axi_fifo_writer #(
  .MAX_OUTSTANDING_BURSTS (4)
) dut (
  .dac_clk_i         (clk),
  .dac_rstn_i        (rstn),
  .start_pulse_i     (start_pulse),
  .set_rst_i         (set_rst),
  .set_axi_start_i   (start_addr),
  .set_axi_stop_i    (stop_addr),
  .axi_sys           (axi),
  .dat_fifo_idata    (fifo_data),
  .dat_fifo_wr       (fifo_wr),
  .dat_fifo_full     (fifo_full),
  .dat_wr_fifo_lvl   (fifo_level),
  .dat_fifo_rst_busy (fifo_rst_busy),
  .axi_fifo_reset    (axi_fifo_reset)
);

task automatic submit_range(input logic [31:0] first, input logic [31:0] last);
  @(negedge clk);
  start_addr = first;
  stop_addr = last;
  start_pulse = 1'b1;
  @(negedge clk);
  start_pulse = 1'b0;
endtask

task automatic expect_request(input logic [31:0] expected_addr,
                              input logic [3:0] expected_len);
  int timeout;
  timeout = 0;
  while (!axi.rvalid && timeout < 100) begin
    @(negedge clk);
    timeout++;
  end
  if (!axi.rvalid)
    $fatal(1, "Timed out waiting for ARVALID");
  if (axi.raddr !== expected_addr || axi.rlen !== expected_len)
    $fatal(1, "Request mismatch: got addr=%08x len=%0d, expected addr=%08x len=%0d",
           axi.raddr, axi.rlen, expected_addr, expected_len);
  arready = 1'b1;
  @(posedge clk);
  #1;
  arready = 1'b0;
endtask

task automatic return_burst(input int beats);
  for (int i = 0; i < beats; i++) begin
    @(negedge clk);
    rvalid = 1'b1;
    rlast = (i == beats-1);
    rdata = 64'(i);
    @(posedge clk);
    #1;
  end
  @(negedge clk);
  rvalid = 1'b0;
  rlast = 1'b0;
endtask

initial begin
  repeat (4) @(posedge clk);
  @(negedge clk);
  rstn = 1'b1;
  repeat (4) @(posedge clk);

  submit_range(32'h0000_1000, 32'h0000_110c);
  expect_request(32'h0000_1000, 4'd15);
  expect_request(32'h0000_1080, 4'd15);
  expect_request(32'h0000_1100, 4'd2);
  return_burst(16);
  return_burst(16);
  return_burst(3);
  if (!dut.wrap_pulse_q || dut.stream_addr_q !== 32'h0000_1000)
    $fatal(1, "Stream pointer did not wrap at the end of the 35-word period");
  expect_request(32'h0000_1000, 4'd15);

  @(negedge clk);
  set_rst = 1'b1;
  wait (dut.restart_flush_active);
  return_burst(16);
  repeat (3) @(posedge clk);
  @(negedge clk);
  set_rst = 1'b0;
  repeat (4) @(posedge clk);

  submit_range(32'h0000_2000, 32'h0000_200c);
  expect_request(32'h0000_2000, 4'd2);
  return_burst(3);
  if (!dut.wrap_pulse_q || dut.stream_addr_q !== 32'h0000_2000)
    $fatal(1, "Stream pointer did not wrap at the end of the 3-word period");
  repeat (2) @(posedge clk);

  @(negedge clk);
  set_rst = 1'b1;
  wait (dut.restart_flush_active);
  repeat (3) @(posedge clk);
  @(negedge clk);
  set_rst = 1'b0;
  repeat (4) @(posedge clk);

  submit_range(32'h0000_3000, 32'h0000_2ffc);
  expect_request(32'h0000_3000, 4'd0);
  return_burst(1);

  @(negedge clk);
  set_rst = 1'b1;
  wait (dut.restart_flush_active);
  repeat (3) @(posedge clk);
  @(negedge clk);
  set_rst = 1'b0;
  repeat (4) @(posedge clk);

  submit_range(32'h0000_4000, 32'h0000_3ff4);
  repeat (20) @(negedge clk);
  if (axi.rvalid)
    $fatal(1, "Empty range incorrectly generated an AXI request");

  @(negedge clk);
  set_rst = 1'b1;
  wait (dut.restart_flush_active);
  repeat (3) @(posedge clk);
  @(negedge clk);
  set_rst = 1'b0;
  repeat (4) @(posedge clk);

  submit_range(32'h0000_0000, 32'hffff_fffb);
  expect_request(32'h0000_0000, 4'd15);
  if (dut.issue_words_left_q !== 32'h1fff_fff0)
    $fatal(1, "Wide range count mismatch: remaining=%08x period=%08x delta=%09x",
           dut.issue_words_left_q, dut.period_words_q, dut.initial_delta_q);

  $display("PASS: burst splitting, wrap, restart flush, empty and wide ranges");
  $finish;
end

endmodule
