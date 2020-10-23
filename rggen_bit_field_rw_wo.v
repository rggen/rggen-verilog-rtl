module rggen_bit_field_rw_wo #(
  parameter             WIDTH         = 8,
  parameter [WIDTH-1:0] INITIAL_VALUE = {WIDTH{1'b0}},
  parameter             WRITE_ONLY    = 1'b0,
  parameter             WRITE_ONCE    = 1'b0
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
  reg   [WIDTH-1:0] r_value;
  wire              w_written;
  wire              w_write_access;

  assign  o_bit_field_read_data = (WRITE_ONLY == 0) ? r_value : {WIDTH{1'b0}};
  assign  o_bit_field_value     = r_value;
  assign  o_value               = r_value;

  generate if (WRITE_ONCE) begin : g
    reg r_written;

    assign  w_written = r_written;
    always @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
        r_written <= 1'b0;
      end
      else if (w_write_access) begin
        r_written <= 1'b1;
      end
    end
  end
  else begin : g
    assign  w_written = 1'b0;
  end endgenerate

  assign  w_write_access  = i_bit_field_valid && (|i_bit_field_write_mask) && (!w_written);
  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_value <= INITIAL_VALUE;
    end
    else if (w_write_access) begin
      r_value <=
        (i_bit_field_write_data & ( i_bit_field_write_mask)) |
        (r_value                & (~i_bit_field_write_mask));
    end
  end
endmodule
