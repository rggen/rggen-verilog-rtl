`include  "rggen_rtl_macros.vh"
module rggen_avalon_bridge #(
  parameter ADDRESS_WIDTH = 8,
  parameter BUS_WIDTH     = 32,
  parameter READ_STROBE   = 1
)(
  input                       i_bus_valid,
  input   [1:0]               i_bus_access,
  input   [ADDRESS_WIDTH-1:0] i_bus_address,
  input   [BUS_WIDTH-1:0]     i_bus_write_data,
  input   [BUS_WIDTH/8-1:0]   i_bus_strobe,
  output                      o_bus_ready,
  output  [1:0]               o_bus_status,
  output  [BUS_WIDTH-1:0]     o_bus_read_data,
  output                      o_read,
  output                      o_write,
  output  [ADDRESS_WIDTH-1:0] o_address,
  output  [BUS_WIDTH/8-1:0]   o_byteenable,
  output  [BUS_WIDTH-1:0]     o_writedata,
  input                       i_waitrequest,
  input   [1:0]               i_response,
  input   [BUS_WIDTH-1:0]     i_readdata
);
  reg r_request_done;

  assign  o_read          = i_bus_valid && (i_bus_access == `RGGEN_READ);
  assign  o_write         = i_bus_valid && (i_bus_access != `RGGEN_READ);
  assign  o_address       = i_bus_address;
  assign  o_byteenable    = (i_bus_access != `RGGEN_READ) ? i_bus_strobe
                          : (READ_STROBE                ) ? i_bus_strobe
                                                          : {BUS_WIDTH/8{1'b1}};
  assign  o_writedata     = i_bus_write_data;
  assign  o_bus_ready     = i_bus_valid && (!i_waitrequest);
  assign  o_bus_status    = i_response;
  assign  o_bus_read_data = i_readdata;
endmodule
