module rggen_bit_field_reserved #(
  parameter WIDTH = 8
)(
  input               i_bit_field_valid,
  input   [WIDTH-1:0] i_bit_field_read_mask,
  input   [WIDTH-1:0] i_bit_field_write_mask,
  input   [WIDTH-1:0] i_bit_field_write_data,
  output  [WIDTH-1:0] o_bit_field_read_data,
  output  [WIDTH-1:0] o_bit_field_value
);
  assign  o_bit_field_read_data = {WIDTH{1'b0}};
  assign  o_bit_field_value     = {WIDTH{1'b0}};
endmodule
