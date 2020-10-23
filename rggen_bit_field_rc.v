module rggen_bit_field_rc #(
  parameter             WIDTH         = 8,
  parameter [WIDTH-1:0] INITIAL_VALUE = {WIDTH{1'b0}}
)(
  input               i_clk,
  input               i_rst_n,
  input               i_bit_field_valid,
  input   [WIDTH-1:0] i_bit_field_read_mask,
  input   [WIDTH-1:0] i_bit_field_write_mask,
  input   [WIDTH-1:0] i_bit_field_write_data,
  output  [WIDTH-1:0] o_bit_field_read_data,
  output  [WIDTH-1:0] o_bit_field_value,
  input   [WIDTH-1:0] i_set,
  input   [WIDTH-1:0] i_mask,
  output  [WIDTH-1:0] o_value,
  output  [WIDTH-1:0] o_value_unmasked
);
  reg   [WIDTH-1:0] r_value;
  wire              w_read_access;

  assign  o_bit_field_read_data = r_value & i_mask;
  assign  o_bit_field_value     = r_value;
  assign  o_value               = r_value & i_mask;
  assign  o_value_unmasked      = r_value;

  assign  w_read_access = i_bit_field_valid && (|i_bit_field_read_mask);
  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_value <= INITIAL_VALUE;
    end
    else if (w_read_access) begin
      r_value <= {WIDTH{1'b0}};
    end
    else begin
      r_value <= r_value | i_set;
    end
  end
endmodule
