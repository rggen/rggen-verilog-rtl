module rggen_bit_field_wrs #(
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
  output  [WIDTH-1:0] o_value
);
  reg [WIDTH-1:0] r_value;

  assign  o_bit_field_read_data = r_value;
  assign  o_bit_field_value     = r_value;
  assign  o_value               = r_value;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_value <= INITIAL_VALUE;
    end
    else if (i_bit_field_valid) begin
      if (|i_bit_field_read_mask) begin
        r_value <= {WIDTH{1'b1}};
      end
      else begin
        r_value <=
          (i_bit_field_write_data & ( i_bit_field_write_mask)) |
          (r_value                & (~i_bit_field_write_mask));
      end
    end
  end
endmodule
