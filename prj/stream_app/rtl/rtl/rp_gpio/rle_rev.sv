////////////////////////////////////////////////////////////////////////////////
// Module: RLE (Run Length Encoding) decompression
// Author: Iztok Jeras
// (c) Red Pitaya  http://www.redpitaya.com
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
// GENERAL DESCRIPTION:
//
// RLE encoded signal decompression
//
////////////////////////////////////////////////////////////////////////////////

module rle_rev #(
  // counter properties
  int unsigned CW = 8,
  int unsigned BW = 8,
  // stream properties
  int unsigned DN = 1,
  type DTI = logic [CW+8-1:0], // data type for input
  type DTO = logic [   8-1:0]  // data type for output
)(
  // input stream input/output
  axi4_stream_if.d sti,  // input
  axi4_stream_if.s sto,  // output
  // configuration
  input  logic     ctl_rst,  // reset
  input  logic     cfg_ena,   // enable
  output logic     new_read  // signals for new FIFO read
);

////////////////////////////////////////////////////////////////////////////////
// A word {count, value} is played for count+1 clocks (count 0: one clock), the
// format the input RLE encoder writes. Without RLE every word is played for one
// clock. The next word is taken on the last clock of the current one; when none
// is ready the output drops TVALID (the GPIO outputs keep the last value).
////////////////////////////////////////////////////////////////////////////////

logic [CW-1:0] cnt;   // clocks played of the current word
logic [CW-1:0] len;   // count of the current word
wire           last = ~cfg_ena | (cnt == len);

assign sti.TREADY = ~sto.TVALID | (sto.TREADY & last);
assign new_read   = sti.TREADY;

always_ff @(posedge sti.ACLK)
if (~sti.ARESETn | ctl_rst) begin
  sto.TVALID <= 1'b0;
  cnt        <= '0;
  len        <= '0;
end else if (sti.TREADY) begin
  sto.TVALID <= sti.TVALID;
  cnt        <= '0;
  if (sti.TVALID)
    len <= sti.TDATA[0][CW+BW-1:BW];
end else if (sto.TREADY) begin
  cnt <= cnt + 1'b1;
end

always_ff @(posedge sti.ACLK)
if (sti.transf) begin
  sto.TLAST    <= sti.TLAST;
  sto.TKEEP    <= '1;
  sto.TDATA[0] <= sti.TDATA[0][BW-1:0];
end

endmodule: rle_rev
