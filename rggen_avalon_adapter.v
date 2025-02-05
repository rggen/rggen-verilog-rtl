`include  "rggen_rtl_macros.vh"
module rggen_avalon_adapter #(
  parameter ADDRESS_WIDTH       = 8,
  parameter LOCAL_ADDRESS_WIDTH = 8,
  parameter BUS_WIDTH           = 32,
  parameter REGISTERS           = 1,
  parameter PRE_DECODE          = 0,
  parameter BASE_ADDRESS        = {ADDRESS_WIDTH{1'b0}},
  parameter BYTE_SIZE           = 256,
  parameter ERROR_STATUS        = 0,
  parameter DEFAULT_READ_DATA   = {BUS_WIDTH{1'b0}},
  parameter INSERT_SLICER       = 0
)(
  input                             i_clk,
  input                             i_rst_n,
  input                             i_read,
  input                             i_write,
  input   [ADDRESS_WIDTH-1:0]       i_address,
  input   [BUS_WIDTH/8-1:0]         i_byteenable,
  input   [BUS_WIDTH-1:0]           i_writedata,
  output                            o_waitrequest,
  output                            o_readdatavalid,
  output                            o_writeresponsevalid,
  output  [1:0]                     o_response,
  output  [BUS_WIDTH-1:0]           o_readdata,
  output                            o_register_valid,
  output  [1:0]                     o_register_access,
  output  [LOCAL_ADDRESS_WIDTH-1:0] o_register_address,
  output  [BUS_WIDTH-1:0]           o_register_write_data,
  output  [BUS_WIDTH-1:0]           o_register_strobe,
  input   [REGISTERS-1:0]           i_register_active,
  input   [REGISTERS-1:0]           i_register_ready,
  input   [2*REGISTERS-1:0]         i_register_status,
  input   [BUS_WIDTH*REGISTERS-1:0] i_register_read_data
);
  wire                      w_request_valid;
  reg                       r_request_valid;
  reg                       r_read;
  reg   [ADDRESS_WIDTH-1:0] r_address;
  reg   [BUS_WIDTH/8-1:0]   r_byteenable;
  reg   [BUS_WIDTH-1:0]     r_writedata;
  reg   [1:0]               r_response_valid;
  reg   [1:0]               r_response;
  reg   [BUS_WIDTH-1:0]     r_readdata;
  wire                      w_bus_valid;
  wire  [1:0]               w_bus_access;
  wire  [ADDRESS_WIDTH-1:0] w_bus_address;
  wire  [BUS_WIDTH-1:0]     w_bus_write_data;
  wire  [BUS_WIDTH/8-1:0]   w_bus_strobe;
  wire                      w_bus_ready;
  wire  [1:0]               w_bus_status;
  wire  [BUS_WIDTH-1:0]     w_bus_read_data;

  assign  o_waitrequest         = r_request_valid;
  assign  o_readdatavalid       = r_response_valid[0];
  assign  o_writeresponsevalid  = r_response_valid[1];
  assign  o_response            = r_response;
  assign  o_readdata            = r_readdata;

  assign  w_request_valid   = i_read || i_write;
  assign  w_bus_valid       = w_request_valid || r_request_valid;
  assign  w_bus_access      = ({r_request_valid, r_read} == 2'b11) ? `RGGEN_READ
                            : ({r_request_valid, r_read} == 2'b10) ? `RGGEN_WRITE
                            : (i_read                            ) ? `RGGEN_READ
                                                                   : `RGGEN_WRITE;
  assign  w_bus_address     = (r_request_valid) ? r_address    : i_address;
  assign  w_bus_write_data  = (r_request_valid) ? r_writedata  : i_writedata;
  assign  w_bus_strobe      = (r_request_valid) ? r_byteenable : i_byteenable;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_request_valid <= 1'b0;
    end
    else if (w_bus_valid && w_bus_ready) begin
      r_request_valid <= 1'b0;
    end
    else if (!r_request_valid) begin
      r_request_valid <= w_request_valid;
    end
  end

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_read        <= 1'b0;
      r_address     <= {ADDRESS_WIDTH{1'b0}};
      r_byteenable  <= {BUS_WIDTH/8{1'b0}};
      r_writedata   <= {BUS_WIDTH{1'b0}};
    end
    else if ({r_request_valid, w_request_valid} == 2'b01) begin
      r_read        <= i_read;
      r_address     <= i_address;
      r_byteenable  <= i_byteenable;
      r_writedata   <= i_writedata;
    end
  end

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_response_valid  <= 2'b00;
    end
    else if (w_bus_valid && w_bus_ready) begin
      if (w_bus_access == `RGGEN_READ) begin
        r_response_valid  <= 2'b01;
      end
      else begin
        r_response_valid  <= 2'b10;
      end
    end
    else begin
      r_response_valid  <= 2'b00;
    end
  end

  always @(posedge i_clk) begin
    if (w_bus_valid && w_bus_ready) begin
      r_response  <= w_bus_status;
      r_readdata  <= w_bus_read_data;
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
    .USE_READ_STROBE      (1                    ),
    .ERROR_STATUS         (ERROR_STATUS         ),
    .DEFAULT_READ_DATA    (DEFAULT_READ_DATA    ),
    .INSERT_SLICER        (INSERT_SLICER        )
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
