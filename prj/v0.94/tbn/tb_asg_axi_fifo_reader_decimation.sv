`timescale 1ns / 1ps

module tb_asg_axi_fifo_reader_decimation;

logic clk = 1'b0;
logic rstn = 1'b0;
logic output_valid_test = 1'b0;
logic cycle_reload_test = 1'b0;
logic [31:0] dec_safe_test = 32'd1;
logic [31:0] expected_dec_cnt;
int unsigned start_reload_count = 0;
int unsigned restart_reload_count = 0;

always #4 clk = ~clk;

rp_asg_axi_fifo_reader dut (
  .dac_o           (),
  .dac_clk_i       (clk),
  .dac_rstn_i      (rstn),
  .trig_i          (1'b0),
  .set_rst_i       (1'b0),
  .set_axi_en_i    (1'b1),
  .set_axi_start_i (32'b0),
  .set_axi_stop_i  (32'b0),
  .set_axi_dec_i   (32'd1),
  .set_cyc_cnt_i   (16'd1),
  .repeat_i        (1'b0),
  .axi_state_o     (),
  .axi_last_o      (),
  .axi_last_pre_o  (),
  .axi_first_o     (),
  .start_pulse_o   (),
  .dat_fifo_out    (64'b0),
  .dat_rd_valid    (1'b0),
  .dat_fifo_empty  (1'b1),
  .dat_rd_fifo_lvl (7'b0),
  .dat_fifo_rd     ()
);

initial begin
  int unsigned seed;
  logic [31:0] random_value;

  seed = 32'h5e71_2026;
  force dut.output_valid = output_valid_test;
  force dut.cycle_reload = cycle_reload_test;
  force dut.dec_safe = dec_safe_test;
  repeat (2) @(posedge clk);
  #1;
  if (dut.dec_cnt_q !== 32'd1)
    $fatal(1, "decimation counter did not reset to one");
  rstn = 1'b1;

  for (int i = 0; i < 1000; i++) begin
    @(negedge clk);
    if (i % 31 == 0) begin
      output_valid_test = 1'b0;
      cycle_reload_test = 1'b1;
      start_reload_count++;
    end else if (i % 31 == 1) begin
      output_valid_test = 1'b1;
      dec_safe_test = dut.dec_cnt_q;
      cycle_reload_test = 1'b1;
      restart_reload_count++;
    end else begin
      random_value = $urandom(seed);
      dec_safe_test = (random_value % 7) + 1;
      random_value = $urandom(seed);
      output_valid_test = (random_value % 4) != 0;
      random_value = $urandom(seed);

      if (!output_valid_test) begin
        cycle_reload_test = random_value[0];
        if (cycle_reload_test)
          start_reload_count++;
      end else begin
        cycle_reload_test = (dut.dec_cnt_q == dec_safe_test) && random_value[0];
        if (cycle_reload_test)
          restart_reload_count++;
      end
    end

    if (cycle_reload_test ||
        !output_valid_test ||
        (dut.dec_cnt_q >= dec_safe_test))
      expected_dec_cnt = 32'd1;
    else
      expected_dec_cnt = dut.dec_cnt_q + 1'b1;

    @(posedge clk);
    #1;
    if (dut.dec_cnt_q !== expected_dec_cnt)
      $fatal(1, "decimation mismatch at cycle %0d: got %0d expected %0d",
             i, dut.dec_cnt_q, expected_dec_cnt);
  end

  $display("reload coverage: start=%0d restart=%0d",
           start_reload_count, restart_reload_count);
  if (start_reload_count == 0 || restart_reload_count == 0)
    $fatal(1, "test did not cover both start and restart reload cases");

  $display("PASS: reader decimation reset equivalence over 1000 cycles");
  $finish;
end

endmodule
