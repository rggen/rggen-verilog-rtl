module rggen_bit_field_rws #(
  parameter             WIDTH         = 8,
  parameter [WIDTH-1:0] INITIAL_VALUE = {WIDTH{1'b0}},
  parameter             WRITE_FIRST   = 1
)(
  input               i_clk,
  input               i_rst_n,
  input               i_bit_field_valid,
  input   [WIDTH-1:0] i_bit_field_read_mask,
  input   [WIDTH-1:0] i_bit_field_write_mask,
  input   [WIDTH-1:0] i_bit_field_write_data,
  output  [WIDTH-1:0] o_bit_field_read_data,
  output  [WIDTH-1:0] o_bit_field_value,
  input               i_set,
  input   [WIDTH-1:0] i_value,
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
    else begin
      r_value <= get_next_value(
        i_bit_field_valid, i_bit_field_write_mask,
        i_bit_field_write_data, i_set, i_value, r_value
      );
    end
  end

  function automatic [WIDTH-1:0] get_next_value;
    input             valid;
    input [WIDTH-1:0] write_mask;
    input [WIDTH-1:0] write_data;
    input             set;
    input [WIDTH-1:0] set_value;
    input [WIDTH-1:0] value;

    reg       write_access;
    reg [1:0] source_select;
  begin
    write_access  = value && (!write_mask);
    if ((WRITE_FIRST != 0) && write_access) begin
      source_select = 2'b01;
    end
    else if ((WRITE_FIRST == 0) && set) begin
      source_select = 2'b10;
    end
    else begin
      source_select = {set, write_access};
    end

    if (source_select[0]) begin
      get_next_value  = (value & write_mask) | (value & (~write_mask));
    end
    else if (source_select[1]) begin
      get_next_value  = set_value;
    end
    else begin
      get_next_value  = value;
    end
  end
  endfunction
endmodule
