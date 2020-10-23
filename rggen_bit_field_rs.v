module rggen_bit_field_rs #(
  parameter WIDTH                     = 8,
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
  input   [WIDTH-1:0] i_clear,
  output  [WIDTH-1:0] o_value
);
  reg   [WIDTH-1:0] r_value;
  wire              w_read_access;
  wire  [WIDTH-1:0] w_set;

  assign  o_bit_field_read_data = r_value;
  assign  o_bit_field_value     = r_value;
  assign  o_value               = r_value;

  assign  w_read_access = i_bit_field_valid && (|i_bit_field_read_mask);
  assign  w_set         = (w_read_access) ? {WIDTH{1'b1}} : {WIDTH{1'b0}};
  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_value <= INITIAL_VALUE;
    end
    else begin
      r_value <= (r_value & (~i_clear)) | w_set;
    end
  end
endmodule
