module rggen_bit_field_w01trg #(
  parameter TRIGGER_VALUE = 1'b0,
  parameter WIDTH         = 8
)(
  input               i_clk,
  input               i_rst_n,
  input               i_sw_valid,
  input   [WIDTH-1:0] i_sw_read_mask,
  input               i_sw_write_enable,
  input   [WIDTH-1:0] i_sw_write_mask,
  input   [WIDTH-1:0] i_sw_write_data,
  output  [WIDTH-1:0] o_sw_read_data,
  output  [WIDTH-1:0] o_sw_value,
  input   [WIDTH-1:0] i_value,
  output  [WIDTH-1:0] o_trigger
);
  reg [WIDTH-1:0] r_trigger;

  assign  o_sw_read_data  = i_value;
  assign  o_sw_value      = r_trigger;
  assign  o_trigger       = r_trigger;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_trigger <= {WIDTH{1'b0}};
    end
    else if (i_sw_valid) begin
      r_trigger <=
        (TRIGGER_VALUE != 0)
          ? i_sw_write_mask & ( i_sw_write_data)
          : i_sw_write_mask & (~i_sw_write_data);
    end
    else if (r_trigger != {WIDTH{1'b0}}) begin
      r_trigger <= {WIDTH{1'b0}};
    end
  end
endmodule
