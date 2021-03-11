module rggen_axi4lite_adapter #(
  parameter                     ID_WIDTH            = 0,
  parameter                     ADDRESS_WIDTH       = 8,
  parameter                     LOCAL_ADDRESS_WIDTH = 8,
  parameter                     BUS_WIDTH           = 32,
  parameter                     REGISTERS           = 1,
  parameter                     PRE_DECODE          = 0,
  parameter [ADDRESS_WIDTH-1:0] BASE_ADDRESS        = {ADDRESS_WIDTH{1'b0}},
  parameter                     BYTE_SIZE           = 256,
  parameter                     ERROR_STATUS        = 0,
  parameter [BUS_WIDTH-1:0]     DEFAULT_READ_DATA   = {BUS_WIDTH{1'b0}},
  parameter                     WRITE_FIRST         = 1,
  parameter                     ACTUAL_ID_WIDTH     = (ID_WIDTH > 0) ? ID_WIDTH : 1
)(
  input                             i_clk,
  input                             i_rst_n,
  input                             i_awvalid,
  output                            o_awready,
  input   [ACTUAL_ID_WIDTH-1:0]     i_awid,
  input   [ADDRESS_WIDTH-1:0]       i_awaddr,
  input   [2:0]                     i_awprot,
  input                             i_wvalid,
  output                            o_wready,
  input   [BUS_WIDTH-1:0]           i_wdata,
  input   [BUS_WIDTH/8-1:0]         i_wstrb,
  output                            o_bvalid,
  input                             i_bready,
  output  [ACTUAL_ID_WIDTH-1:0]     o_bid,
  output  [1:0]                     o_bresp,
  input                             i_arvalid,
  output                            o_arready,
  input   [ACTUAL_ID_WIDTH-1:0]     i_arid,
  input   [ADDRESS_WIDTH-1:0]       i_araddr,
  input   [2:0]                     i_arprot,
  output                            o_rvalid,
  input                             i_rready,
  output  [ACTUAL_ID_WIDTH-1:0]     o_rid,
  output  [1:0]                     o_rresp,
  output  [BUS_WIDTH-1:0]           o_rdata,
  output                            o_register_valid,
  output  [1:0]                     o_register_access,
  output  [LOCAL_ADDRESS_WIDTH-1:0] o_register_address,
  output  [BUS_WIDTH-1:0]           o_register_write_data,
  output  [BUS_WIDTH/8-1:0]         o_register_strobe,
  input   [REGISTERS-1:0]           i_register_active,
  input   [REGISTERS-1:0]           i_register_ready,
  input   [2*REGISTERS-1:0]         i_register_status,
  input   [BUS_WIDTH*REGISTERS-1:0] i_register_read_data
);
  localparam  [1:0] RGGEN_WRITE           = 2'b11;
  localparam  [1:0] RGGEN_READ            = 2'b10;
  localparam  [1:0] IDLE                  = 2'b00;
  localparam  [1:0] BUS_ACCESS_BUSY       = 2'b01;
  localparam  [1:0] WAIT_FOR_RESPONSE_ACK = 2'b10;

  wire                      w_bus_valid;
  wire  [1:0]               w_bus_access;
  wire  [ADDRESS_WIDTH-1:0] w_bus_address;
  wire  [BUS_WIDTH-1:0]     w_bus_write_data;
  wire  [BUS_WIDTH/8-1:0]   w_bus_strobe;
  wire                      w_bus_ready;
  wire  [1:0]               w_bus_status;
  wire  [BUS_WIDTH-1:0]     w_bus_read_data;
  reg   [1:0]               r_state;

  //  Request
  wire  [1:0]               w_request_valid;
  wire  [2:0]               w_request_ready;
  reg   [1:0]               r_access;
  reg   [ADDRESS_WIDTH-1:0] r_address;
  reg   [BUS_WIDTH-1:0]     r_write_data;
  reg   [BUS_WIDTH/8-1:0]   r_strobe;

  assign  o_awready = w_request_ready[0];
  assign  o_wready  = w_request_ready[1];
  assign  o_arready = w_request_ready[2];

  assign  w_bus_valid
    = (r_state == BUS_ACCESS_BUSY) ? 1'b1
    : (r_state == IDLE           ) ? |w_request_valid
                                   : 1'b0;
  assign  w_bus_access
    = ((r_state == IDLE) && w_request_valid[0]) ? RGGEN_WRITE
    : ((r_state == IDLE) && w_request_valid[1]) ? RGGEN_READ
                                                : r_access;
  assign  w_bus_address
    = ((r_state == IDLE) && w_request_valid[0]) ? i_awaddr
    : ((r_state == IDLE) && w_request_valid[1]) ? i_araddr
                                                : r_address;
  assign  w_bus_write_data
    = ((r_state == IDLE) && w_request_valid[0]) ? i_wdata
                                                : r_write_data;
  assign  w_bus_strobe
    = ((r_state == IDLE) && w_request_valid[0]) ? i_wstrb
                                                : r_strobe;

  assign  w_request_valid = get_request_valid(i_awvalid, i_wvalid, i_arvalid);
  assign  w_request_ready = get_request_ready(r_state, i_awvalid, i_wvalid, i_arvalid);

  always @(posedge i_clk) begin
    if ((r_state == IDLE) && (|w_request_valid)) begin
      r_access      <= w_bus_access;
      r_address     <= w_bus_address;
      r_write_data  <= w_bus_write_data;
      r_strobe      <= w_bus_strobe;
    end
  end

  function automatic [1:0] get_request_valid;
    input awvalid;
    input wvalid;
    input arvalid;

    reg write_valid;
    reg read_valid;
  begin
    if (WRITE_FIRST) begin
      write_valid = awvalid && wvalid;
      read_valid  = arvalid && (!write_valid);
    end
    else begin
      read_valid  = arvalid;
      write_valid = awvalid && wvalid && (!read_valid);
    end
    get_request_valid = {read_valid, write_valid};
  end
  endfunction

  function automatic [2:0] get_request_ready;
    input [1:0] state;
    input       awvalid;
    input       wvalid;
    input       arvalid;

    reg awready;
    reg wready;
    reg arready;
  begin
    if (WRITE_FIRST) begin
      awready = wvalid;
      wready  = awvalid;
      arready = !(awvalid && wvalid);
    end
    else begin
      arready = 1'b1;
      awready = (!arvalid) && wvalid;
      wready  = (!arvalid) && awvalid;
    end

    if (state == IDLE) begin
      get_request_ready = {arready, wready, awready};
    end
    else begin
      get_request_ready = 3'b000;
    end
  end
  endfunction

  //  Response
  reg   [1:0]                 r_response_valid;
  wire                        w_response_ack;
  wire  [ACTUAL_ID_WIDTH-1:0] w_id;
  reg   [BUS_WIDTH-1:0]       r_read_data;
  reg   [1:0]                 r_status;

  assign  o_bvalid  = r_response_valid[0];
  assign  o_bid     = w_id;
  assign  o_bresp   = r_status;
  assign  o_rvalid  = r_response_valid[1];
  assign  o_rid     = w_id;
  assign  o_rdata   = r_read_data;
  assign  o_rresp   = r_status;

  assign  w_response_ack  =
    (r_response_valid[0] && i_bready) ||
    (r_response_valid[1] && i_rready);
  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_response_valid  <= 2'b00;
    end
    else if (w_response_ack) begin
      r_response_valid  <= 2'b00;
    end
    else if (w_bus_valid && w_bus_ready) begin
      if (w_bus_access == RGGEN_WRITE) begin
        r_response_valid  <= 2'b01;
      end
      else begin
        r_response_valid  <= 2'b10;
      end
    end
  end

  generate if (ID_WIDTH >= 1) begin : g_id
    reg [ID_WIDTH-1:0]  r_id;

    assign  w_id  = r_id;
    always @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
        r_id  <= {ID_WIDTH{1'b0}};
      end
      else if (i_awvalid && w_request_ready[0]) begin
        r_id  <= i_awid;
      end
      else if (i_arvalid && w_request_ready[2]) begin
        r_id  <= i_arid;
      end
    end
  end
  else begin : g_id
    assign  w_id  = 1'b0;
  end endgenerate

  always @(posedge i_clk) begin
    if (w_bus_valid && w_bus_ready) begin
      r_read_data <= w_bus_read_data;
      r_status    <= w_bus_status;
    end
  end

  //  State machine
  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_state <= IDLE;
    end
    else begin
      case (r_state)
        IDLE: begin
          if (w_bus_valid && w_bus_ready) begin
            r_state <= WAIT_FOR_RESPONSE_ACK;
          end
          else if (w_bus_valid) begin
            r_state <= BUS_ACCESS_BUSY;
          end
        end
        BUS_ACCESS_BUSY: begin
          if (w_bus_ready) begin
            r_state <= WAIT_FOR_RESPONSE_ACK;
          end
        end
        WAIT_FOR_RESPONSE_ACK: begin
          if (w_response_ack) begin
            r_state <= IDLE;
          end
        end
      endcase
    end
  end

  //  Adapter common
  rggen_adapter_common #(
    .ADDRESS_WIDTH        (ADDRESS_WIDTH        ),
    .LOCAL_ADDRESS_WIDTH  (LOCAL_ADDRESS_WIDTH  ),
    .BUS_WIDTH            (BUS_WIDTH            ),
    .REGISTERS            (REGISTERS            ),
    .PRE_DECODE           (PRE_DECODE           ),
    .BASE_ADDRESS         (BASE_ADDRESS         ),
    .BYTE_SIZE            (BYTE_SIZE            ),
    .ERROR_STATUS         (ERROR_STATUS         ),
    .DEFAULT_READ_DATA    (DEFAULT_READ_DATA    )
  ) u_adapter_common (
    .i_clk                  (i_clk                  ),
    .i_rst_n                (i_rst_n                ),
    .i_bus_valid            (w_bus_valid            ),
    .i_bus_access           (w_bus_access           ),
    .i_bus_address          (w_bus_address          ),
    .i_bus_write_data       (w_bus_write_data       ),
    .i_bus_strobe           (w_bus_strobe           ),
    .o_bus_ready            (w_bus_ready            ),
    .o_bus_status           (w_bus_status           ),
    .o_bus_read_data        (w_bus_read_data        ),
    .o_register_valid       (o_register_valid       ),
    .o_register_access      (o_register_access      ),
    .o_register_address     (o_register_address     ),
    .o_register_write_data  (o_register_write_data  ),
    .o_register_strobe      (o_register_strobe      ),
    .i_register_active      (i_register_active      ),
    .i_register_ready       (i_register_ready       ),
    .i_register_status      (i_register_status      ),
    .i_register_read_data   (i_register_read_data   )
  );
endmodule
