`include  "rggen_rtl_macros.vh"
module rggen_maskable_register #(
  parameter READABLE        = 1'b1,
  parameter WRITABLE        = 1'b1,
  parameter ADDRESS_WIDTH   = 8,
  parameter OFFSET_ADDRESS  = {ADDRESS_WIDTH{1'b0}},
  parameter BUS_WIDTH       = 32,
  parameter DATA_WIDTH      = BUS_WIDTH
)(
  input                       i_clk,
  input                       i_rst_n,
  input                       i_register_valid,
  input   [1:0]               i_register_access,
  input   [ADDRESS_WIDTH-1:0] i_register_address,
  input   [BUS_WIDTH-1:0]     i_register_write_data,
  input   [BUS_WIDTH-1:0]     i_register_strobe,
  output                      o_register_active,
  output                      o_register_ready,
  output  [1:0]               o_register_status,
  output  [BUS_WIDTH-1:0]     o_register_read_data,
  output  [DATA_WIDTH-1:0]    o_register_value,
  output                      o_bit_field_write_valid,
  output                      o_bit_field_read_valid,
  output  [DATA_WIDTH-1:0]    o_bit_field_mask,
  output  [DATA_WIDTH-1:0]    o_bit_field_write_data,
  input   [DATA_WIDTH-1:0]    i_bit_field_read_data,
  input   [DATA_WIDTH-1:0]    i_bit_field_value
);
  localparam  HALF_WIDTH  = BUS_WIDTH / 2;

  function [BUS_WIDTH-1:0] get_mask;
    input [1:0]           access;
    input [BUS_WIDTH-1:0] write_data;
    input [BUS_WIDTH-1:0] strobe;

    reg [HALF_WIDTH-1:0]  write_data_mask;
  begin
    if (access != `RGGEN_READ) begin
      write_data_mask = write_data[1*HALF_WIDTH+:HALF_WIDTH] & strobe[1*HALF_WIDTH+:HALF_WIDTH];
    end
    else begin
      write_data_mask = {HALF_WIDTH{1'b1}};
    end

    get_mask  = {{HALF_WIDTH{1'b0}}, write_data_mask};
  end
  endfunction

  wire  [BUS_WIDTH-1:0] w_mask;
  assign  w_mask  = get_mask(i_register_access, i_register_write_data, i_register_strobe);

  rggen_register_common #(
    .READABLE             (READABLE       ),
    .WRITABLE             (WRITABLE       ),
    .ADDRESS_WIDTH        (ADDRESS_WIDTH  ),
    .OFFSET_ADDRESS       (OFFSET_ADDRESS ),
    .BUS_WIDTH            (BUS_WIDTH      ),
    .DATA_WIDTH           (DATA_WIDTH     ),
    .USE_ADDITIONAL_MASK  (1'b1           )
  ) u_register_common (
    .i_clk                    (i_clk                    ),
    .i_rst_n                  (i_rst_n                  ),
    .i_register_valid         (i_register_valid         ),
    .i_register_access        (i_register_access        ),
    .i_register_address       (i_register_address       ),
    .i_register_write_data    (i_register_write_data    ),
    .i_register_strobe        (i_register_strobe        ),
    .o_register_active        (o_register_active        ),
    .o_register_ready         (o_register_ready         ),
    .o_register_status        (o_register_status        ),
    .o_register_read_data     (o_register_read_data     ),
    .o_register_value         (o_register_value         ),
    .i_additional_match       (1'b1                     ),
    .i_additional_mask        (w_mask                   ),
    .o_bit_field_write_valid  (o_bit_field_write_valid  ),
    .o_bit_field_read_valid   (o_bit_field_read_valid   ),
    .o_bit_field_mask         (o_bit_field_mask         ),
    .o_bit_field_write_data   (o_bit_field_write_data   ),
    .i_bit_field_read_data    (i_bit_field_read_data    ),
    .i_bit_field_value        (i_bit_field_value        )
  );
endmodule
