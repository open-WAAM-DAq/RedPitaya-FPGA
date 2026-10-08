`timescale 1ns / 1ps

module tb_asg_pointer_math;

localparam int PNT_SIZE = 62;
localparam int SIZE_W = 30;

logic [PNT_SIZE-1:0] pointer;
logic [PNT_SIZE-1:0] step;
logic [SIZE_W-1:0] size;
logic advance;
logic [PNT_SIZE:0] next_pointer;
logic [PNT_SIZE:0] wrapped_pointer;
logic below_limit;

logic [PNT_SIZE:0] expected_next;
logic [PNT_SIZE:0] expected_limit;
logic [PNT_SIZE:0] expected_wrapped;
logic expected_below_limit;

rp_asg_pointer_math #(
  .PNT_SIZE (PNT_SIZE),
  .SIZE_W   (SIZE_W)
) dut (
  .pointer_i         (pointer),
  .step_i            (step),
  .size_i            (size),
  .advance_i         (advance),
  .next_pointer_o    (next_pointer),
  .wrapped_pointer_o (wrapped_pointer),
  .below_limit_o     (below_limit)
);

task automatic check_math(
  input logic [PNT_SIZE-1:0] start_pointer,
  input logic [PNT_SIZE-1:0] increment,
  input logic [SIZE_W-1:0]   range_size,
  input logic                do_advance
);
  begin
    pointer = start_pointer;
    step = increment;
    size = range_size;
    advance = do_advance;
    #1;

    if (do_advance)
      expected_next = {1'b0,start_pointer} + {1'b0,increment};
    else
      expected_next = {1'b0,start_pointer};
    expected_limit = {1'b0,range_size,32'b0} + 1'b1;
    expected_below_limit = expected_next < expected_limit;
    expected_wrapped = expected_next - expected_limit;

    if (next_pointer !== expected_next ||
        below_limit !== expected_below_limit ||
        wrapped_pointer !== expected_wrapped)
      $fatal(1, "Pointer math mismatch: next=%h expected=%h below=%b expected_below=%b wrapped=%h expected_wrapped=%h",
             next_pointer, expected_next, below_limit, expected_below_limit,
             wrapped_pointer, expected_wrapped);
  end
endtask

initial begin
  check_math({30'd1,32'hffff_fff0}, {30'd0,32'h0000_0030}, 30'd2, 1'b1);
  check_math({30'd2,32'hffff_ffff}, {30'd0,32'h0000_0002}, 30'd3, 1'b1);
  check_math({30'd1,32'h0000_0020}, {30'd0,32'h0000_0010}, 30'd2, 1'b1);
  check_math({30'd3,32'h0000_0000}, {30'd0,32'h0000_0000}, 30'd3, 1'b0);
  check_math({30'h3fff_ffff,32'hffff_ffff}, 62'd1, 30'h3fff_ffff, 1'b1);
  check_math({30'd0,32'h0000_0000}, 62'd0, 30'd0, 1'b1);
  check_math({30'd0,32'h0000_0000}, {30'd1,32'd1}, 30'd1, 1'b1);
  check_math({30'd0,32'h0000_0000}, {30'd1,32'd2}, 30'd1, 1'b1);

  $display("PASS: segmented pointer addition and wrap boundaries");
  $finish;
end

endmodule
