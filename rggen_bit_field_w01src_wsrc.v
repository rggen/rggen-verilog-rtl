module rggen_bit_field_w01src_wsrc #(
  parameter [1:0]       SET_VALUE     = 2'b00,
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
      r_value <= get_next_value(
        i_bit_field_read_mask, i_bit_field_write_mask,
        i_bit_field_write_data, r_value
      );
    end
  end

  function automatic [WIDTH-1:0] get_next_value;
    input [WIDTH-1:0] read_mask;
    input [WIDTH-1:0] write_mask;
    input [WIDTH-1:0] write_data;
    input [WIDTH-1:0] value;

    reg [WIDTH-1:0] clear;
    reg [WIDTH-1:0] set;
  begin
    if (|read_mask) begin
      clear = {WIDTH{1'b1}};
    end
    else begin
      clear = {WIDTH{1'b0}};
    end

    if (|write_mask) begin
      case (SET_VALUE)
        2'b00:    set = write_mask & (~write_data);
        2'b01:    set = write_mask & ( write_data);
        default:  set = {WIDTH{1'b1}};
      endcase
    end
    else begin
      set = {WIDTH{1'b0}};
    end

    get_next_value  = (value & (~clear)) | set;
  end
  endfunction
endmodule
