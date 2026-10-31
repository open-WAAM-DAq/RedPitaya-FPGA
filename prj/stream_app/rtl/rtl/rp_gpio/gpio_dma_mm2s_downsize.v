`timescale 1ns / 1ps

module gpio_dma_mm2s_downsize
  #(parameter AXI_DATA_BITS   = 64,
    parameter AXIS_DATA_BITS  = 16,     
    parameter AXI_BURST_LEN   = 16)(    
  input  wire                       clk,
  input  wire                       rst,
  
  input  wire                       fifo_empty,
  input  wire                       fifo_full,

  input  wire [AXI_DATA_BITS-1:0]   fifo_rd_data,
  output wire                       fifo_rd_re,
    
  output reg  [AXIS_DATA_BITS-1:0]  m_axis_tdata,
  output wire                       m_axis_tvalid,
  input  wire                       m_axis_tready,

  // trigger mode: after the FIFO filled up the output waits for a rising edge of the trigger
  input  wire                       trigger_mode_i,
  input  wire                       trigger_i,
  output wire                       armed_o
);

reg  [2:0]  rd_cnt;
reg         first_full;


reg         started, trigger_d1;
// plays once the FIFO is full, in the trigger mode only after the trigger; clearing the
// trigger mode while armed starts at once (as the DAC)
wire        play = first_full & (~trigger_mode_i | started);

always @(posedge clk)
begin
  if (rst == 0) begin
    started    <= 1'b0;
    trigger_d1 <= 1'b0;
  end else begin
    trigger_d1 <= trigger_i;
    if (first_full & trigger_mode_i & trigger_i & ~trigger_d1)
      started <= 1'b1;
  end
end

assign armed_o = trigger_mode_i & first_full & ~started;

// FIFO read pulse: the upper half of a word is taken
assign fifo_rd_re     = (rd_cnt == 'd1) & m_axis_tready & m_axis_tvalid;

// a half word is offered while the FIFO (first word fall through) holds data
assign m_axis_tvalid  = play & ~fifo_empty;

// must wait to fill up the FIFO before starting to read
always @(posedge clk)
begin
  if (rst == 0) begin
    first_full <= 'b0;
  end else begin 
    if (fifo_full & ~fifo_empty & ~first_full)
      first_full <= 'h1;
  end
end

// output select counter: downsize from 64 to 32 bit
always @(posedge clk)
begin
  if (rst == 0)
    rd_cnt <= 'd0;
  else if (m_axis_tvalid & m_axis_tready)
    rd_cnt <= (rd_cnt == 'd0) ? 'd1 : 'd0;
end

// output data mux
always @(*)
begin
  case(rd_cnt)
    'd1:     m_axis_tdata = fifo_rd_data[63:32];
    default: m_axis_tdata = fifo_rd_data[31: 0];
  endcase
end

endmodule