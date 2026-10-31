#!/bin/bash
# Runs la_dma_tb (LA capture into the S2MM side of the DMA, 250-12) in xsim, in the
# docker image vivado:2025.1 by default. The stream IP of the block design is
# generated with the parameters of prj/logic/ip/system.tcl.
#   la_dma_run.sh            MODE 0 (wide, the design), 1 (the design before), 2 (negative control)
#   la_dma_run.sh "3 4"      the 125 MS/s boards as built (3) and widened to 32 bit (4)
#   la_dma_run.sh 0 nostall  one MODE, DMA sink always ready
# Prints the ok/FAIL/PASS lines of every run.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
FPGA=$(cd "$HERE/../../.." && pwd)
WORK=${WORK:-$(mktemp -d)}
IMAGE=${IMAGE:-vivado:2025.1}
MODES=${1:-"0 1 2"}
PLUS=""
[ "$2" = "nostall" ] && PLUS="-testplusarg nostall"
R=$FPGA/rtl/rtl_250

cat > "$WORK/sim.tcl" <<TCL
create_project -force la_dma $WORK/prj -part xc7z020clg400-1
set_property target_language Verilog [current_project]
proc ip {name mod cfg} {
  create_ip -name \$name -vendor xilinx.com -library ip -module_name \$mod
  set_property -dict \$cfg [get_ips \$mod]
}
ip axis_dwidth_converter la_dw16to64 {CONFIG.S_TDATA_NUM_BYTES 2 CONFIG.M_TDATA_NUM_BYTES 8 CONFIG.HAS_TLAST 1 CONFIG.HAS_TKEEP 1}
ip axis_clock_converter  la_cc64     {CONFIG.TDATA_NUM_BYTES 8 CONFIG.HAS_TLAST 1 CONFIG.HAS_TKEEP 1}
ip axis_clock_converter  la_cc16     {CONFIG.TDATA_NUM_BYTES 2 CONFIG.HAS_TLAST 1 CONFIG.HAS_TKEEP 1}
ip axis_data_fifo        la_fifo64   {CONFIG.TDATA_NUM_BYTES 8 CONFIG.FIFO_DEPTH 2048 CONFIG.FIFO_MODE 2 CONFIG.IS_ACLK_ASYNC 0 CONFIG.HAS_TLAST 1 CONFIG.HAS_TKEEP 1}
ip axis_dwidth_converter la_dw16to32 {CONFIG.S_TDATA_NUM_BYTES 2 CONFIG.M_TDATA_NUM_BYTES 4 CONFIG.HAS_TLAST 1 CONFIG.HAS_TKEEP 1}
ip axis_clock_converter  la_cc32     {CONFIG.TDATA_NUM_BYTES 4 CONFIG.HAS_TLAST 1 CONFIG.HAS_TKEEP 1}
ip axis_data_fifo        la_fifo32   {CONFIG.TDATA_NUM_BYTES 4 CONFIG.FIFO_DEPTH 2048 CONFIG.FIFO_MODE 2 CONFIG.IS_ACLK_ASYNC 0 CONFIG.HAS_TLAST 1 CONFIG.HAS_TKEEP 1}
ip axis_data_fifo        la_fifo16   {CONFIG.TDATA_NUM_BYTES 2 CONFIG.FIFO_DEPTH 2048 CONFIG.FIFO_MODE 2 CONFIG.IS_ACLK_ASYNC 0 CONFIG.HAS_TLAST 1 CONFIG.HAS_TKEEP 1}
generate_target simulation [get_ips]
add_files -fileset sim_1 [list \
  $R/interface/axi4_stream_if.sv $R/interface/sys_bus_if.sv \
  $R/str_dec.sv $R/la_trg.sv $R/old_acq.sv $R/rle.sv $R/axi4_stream_cnt.sv $R/axi4_stream_reg.sv \
  $R/old_la_top.sv $HERE/la_dma_tb.sv]
set_property top la_dma_tb [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.xsim.more_options} -value {$PLUS} -objects [get_filesets sim_1]
foreach m {$MODES} {
  set_property generic "MODE=\$m" [get_filesets sim_1]
  launch_simulation -simset sim_1 -mode behavioral
  close_sim
}
TCL

run="cd $WORK && vivado -mode batch -nojournal -nolog -source sim.tcl > sim.log 2>&1; grep -E '^(MODE|ok|FAIL|PASS| +sample)' sim.log"
if command -v xvlog >/dev/null; then
  bash -c "$run"
else
  docker run --rm -v /dev/null:/lib/x86_64-linux-gnu/libudev.so.1:ro -v "$FPGA:$FPGA" -v "$WORK:$WORK" \
    --user "$(id -u):$(id -g)" -e HOME=/tmp "$IMAGE" bash -lc "$run"
fi
