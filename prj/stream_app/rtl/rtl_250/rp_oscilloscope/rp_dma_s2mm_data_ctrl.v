`timescale 1ns / 1ps

module rp_dma_s2mm_data_ctrl(
  input  wire       m_axi_aclk,
  input  wire       m_axi_aresetn,
  input  wire       fifo_rst,
  //
  output reg        busy,
  //
  input  wire [7:0] req_data,
  input  wire       req_we,
  output reg  [7:0] req_xfer_cnt,
  input  wire [1:0] req_mark,         // the request starts buffer 1 (bit 0) or 2 (bit 1)
  output wire [1:0] first_beat_mark,  // the mark of the request during its first beat
  //  
  output reg        m_axi_wvalid,    
  input  wire       m_axi_wready,    
  output reg        m_axi_wlast                        
);

///////////////////////////////////////////////////////////
// Parameters
//////////////////////////////////////////////////////////// 

localparam IDLE           = 1'd0;
localparam SEND_AXI_DATA  = 1'd1;

////////////////////////////////////////////////////////////
// Signals
//////////////////////////////////////////////////////////// 

reg  [0:0]    state_cs;                // Current state
reg  [0:0]    state_ns;                // Next state  
reg  [199:0]  state_ascii;             // ASCII state
wire [7:0]    fifo_wr_data; 
wire          fifo_wr_we;
wire [7:0]    fifo_rd_data;
wire [1:0]    fifo_rd_mark;
reg  [1:0]    cur_mark;
reg           first_pend;
reg           fifo_rd_re;
wire          fifo_empty;

fifo_axi_req U_fifo_axi_req(
  .wr_clk (m_axi_aclk),
  .rd_clk (m_axi_aclk),      
  .rst    (fifo_rst),      
  .din    ({req_mark, fifo_wr_data}),
  .wr_en  (fifo_wr_we),  
  .full   (),  
  .dout   ({fifo_rd_mark, fifo_rd_data}),
  .rd_en  (fifo_rd_re), 
  .empty  (fifo_empty));

assign fifo_wr_data = req_data;
assign fifo_wr_we   = req_we;

always @(posedge m_axi_aclk)
begin
  if ((m_axi_aresetn == 0) || fifo_rst) begin
    cur_mark   <= 2'b00;
    first_pend <= 1'b0;
  end else if (fifo_rd_re) begin
    cur_mark   <= fifo_rd_mark;
    first_pend <= 1'b1;
  end else if (m_axi_wvalid && m_axi_wready) begin
    first_pend <= 1'b0;
  end
end

assign first_beat_mark = (m_axi_wvalid && m_axi_wready && first_pend) ? cur_mark : 2'b00;

////////////////////////////////////////////////////////////
// Name : State machine seq logic
// Sets the current state to the next state.
////////////////////////////////////////////////////////////

always @(posedge m_axi_aclk)
begin
  if (m_axi_aresetn == 0) begin
    state_cs <= IDLE;
  end else begin
    state_cs <= state_ns;
  end
end

////////////////////////////////////////////////////////////
// Name : State machine ascii 
// Converts the state to ascii for debug.
////////////////////////////////////////////////////////////

always @(*)
begin
  case (state_cs)
    IDLE:           state_ascii = "IDLE";
    SEND_AXI_DATA:  state_ascii = "SEND_AXI_DATA";
  endcase
end

////////////////////////////////////////////////////////////
// Name : State machine comb logic
// Assigns the next state.
////////////////////////////////////////////////////////////

always @(*)
begin
  state_ns = state_cs;

  case (state_cs)
    // IDLE - Wait for a request in the FIFO
    IDLE: begin
      if (fifo_empty == 0) begin
        state_ns = SEND_AXI_DATA;
      end
    end
    
    // SEND_AXI_DATA - Transfer the AXI data 
    SEND_AXI_DATA: begin
      if ((m_axi_wvalid == 1) && (m_axi_wready == 1) && (m_axi_wlast == 1)) begin
        state_ns = IDLE;
      end      
    end
  endcase
end

////////////////////////////////////////////////////////////
// Name : Busy
// Indicates that there are requests in the queue of data 
// is being sent
////////////////////////////////////////////////////////////

always @(posedge m_axi_aclk)
begin
  if (m_axi_aresetn == 0) begin
    busy <= 0;
  end else begin
    if (req_we == 1) begin
      busy <= 1;  
    end else begin
      if ((fifo_empty == 1) && 
          ((m_axi_wvalid == 1) && (m_axi_wready == 1) && (m_axi_wlast == 1))) begin
        busy <= 0;
      end
    end
  end
end

////////////////////////////////////////////////////////////
// Name : Master AXI WVALID
// 
////////////////////////////////////////////////////////////

always @(posedge m_axi_aclk)
begin
  if (m_axi_aresetn == 0) begin
    m_axi_wvalid <= 0;
  end else begin
    case (state_cs) 
      // IDLE - Wait for a request in the FIFO
      IDLE: begin
        if (fifo_empty == 0) begin
          m_axi_wvalid <= 1;
        end else begin
          m_axi_wvalid <= 0;
        end
      end  
      
      // SEND_AXI_DATA - Transfer the AXI data 
      SEND_AXI_DATA: begin
        if ((m_axi_wvalid == 1) && (m_axi_wready == 1) && (m_axi_wlast == 1)) begin
          m_axi_wvalid <= 0;
        end      
      end      
    endcase   
  end
end

////////////////////////////////////////////////////////////
// Name : Master AXI WLAST
// 
////////////////////////////////////////////////////////////

always @(posedge m_axi_aclk)
begin
  if (m_axi_aresetn == 0) begin
    m_axi_wlast <= 0;
  end else begin
    case (state_cs) 
      // IDLE - Wait for a request in the FIFO
      IDLE: begin
        if (fifo_empty == 0) begin
          if (fifo_rd_data == 1) begin
            m_axi_wlast <= 1;
          end else begin
            m_axi_wlast <= 0;
          end
        end 
      end  
      
      // SEND_AXI_DATA - Transfer the AXI data 
      SEND_AXI_DATA: begin
        if ((m_axi_wvalid == 1) && (m_axi_wready == 1)) begin
          if (m_axi_wlast == 1) begin
            m_axi_wlast <= 0;        
          end else begin
            if (req_xfer_cnt == 2) begin
              m_axi_wlast <= 1;  
            end        
          end
        end      
      end      
    endcase   
  end
end

////////////////////////////////////////////////////////////
// Name : FIFO Read Enable
// Reads requests from the FIFO when available. 
////////////////////////////////////////////////////////////

always @(*)
begin
  fifo_rd_re = 0;
        
  case (state_cs) 
    // IDLE - Wait for a request in the FIFO
    IDLE: begin
      if (fifo_empty == 0) begin
        fifo_rd_re = 1;
      end 
    end  
  endcase   
end

////////////////////////////////////////////////////////////
// Name : Transfer Count
// Counts the AXI transfers in the request.
////////////////////////////////////////////////////////////

always @(posedge m_axi_aclk)
begin
  case (state_cs) 
    // IDLE - Wait for a request in the FIFO
    IDLE: begin
      req_xfer_cnt <= fifo_rd_data;
    end  
    
    // SEND_AXI_DATA - Transfer the AXI data 
    SEND_AXI_DATA: begin
      if ((m_axi_wvalid == 1) && (m_axi_wready == 1)) begin
        if (m_axi_wlast == 1) begin
          req_xfer_cnt <= fifo_rd_data; 
        end else begin
          req_xfer_cnt <= req_xfer_cnt - 1;     
        end       
      end      
    end      
  endcase   
end

endmodule