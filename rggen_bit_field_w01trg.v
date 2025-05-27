module rggen_bit_field_w01trg #(
  parameter TRIGGER_VALUE = 1'b0,
  parameter WIDTH         = 8
)(
  input               i_clk,
  input               i_rst_n,
  input               i_sw_read_valid,
  input               i_sw_write_valid,
  input               i_sw_write_enable,
  input   [WIDTH-1:0] i_sw_mask,
  input   [WIDTH-1:0] i_sw_write_data,
  output  [WIDTH-1:0] o_sw_read_data,
  output  [WIDTH-1:0] o_sw_value,
  input   [WIDTH-1:0] i_value,
  output  [WIDTH-1:0] o_trigger
);
  reg [WIDTH-1:0] r_trigger;
  integer         i;

  assign  o_sw_read_data  = i_value;
  assign  o_sw_value      = r_trigger;
  assign  o_trigger       = r_trigger;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_trigger <= {WIDTH{1'b0}};
    end
    else begin
      for (i = 0;i < WIDTH;i = i + 1) begin
        if (i_sw_write_valid && i_sw_mask[i] && (i_sw_write_data[i] == TRIGGER_VALUE)) begin
          r_trigger[i]  <= 1'b1;
        end
        else if (r_trigger[i]) begin
          r_trigger[i]  <= 1'b0;
        end
      end
    end
  end
endmodule
