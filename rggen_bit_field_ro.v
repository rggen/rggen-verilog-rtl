module rggen_bit_field_ro #(
  parameter WIDTH = 8
)(
  input               i_bit_field_valid,
  input   [WIDTH-1:0] i_bit_field_read_mask,
  input   [WIDTH-1:0] i_bit_field_write_mask,
  input   [WIDTH-1:0] i_bit_field_write_data,
  output  [WIDTH-1:0] o_bit_field_read_data,
  output  [WIDTH-1:0] o_bit_field_value,
  input   [WIDTH-1:0] i_value
);
  assign  o_bit_field_read_data = i_value;
  assign  o_bit_field_value     = i_value;
endmodule
