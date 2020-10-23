module rggen_bit_field_w01s_ws_wos #(
  parameter [1:0]       SET_VALUE     = 2'b00,
  parameter             WRITE_ONLY    = 1'b0,
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
  input   [WIDTH-1:0] i_clear,
  output  [WIDTH-1:0] o_value
);
  reg [WIDTH-1:0] r_value;

  assign  o_bit_field_read_data = (WRITE_ONLY == 0) ? r_value : {WIDTH{1'b0}};
  assign  o_bit_field_value     = r_value;
  assign  o_value               = r_value;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_value <= INITIAL_VALUE;
    end
    else begin
      r_value <= get_next_value(
        i_bit_field_valid, i_bit_field_write_mask,
        i_bit_field_write_data, i_clear, r_value
      );
    end
  end

  function automatic [WIDTH-1:0] get_next_value;
    input             valid;
    input [WIDTH-1:0] write_mask;
    input [WIDTH-1:0] write_data;
    input [WIDTH-1:0] clear;
    input [WIDTH-1:0] value;

    reg [WIDTH-1:0] set;
  begin
    if (valid && (|write_mask)) begin
      case (SET_VALUE)
        2'b00:    set = write_mask & (~write_data);
        2'b01:    set = write_mask & ( write_data);
        default:  set = {WIDTH{1'b1}};
      endcase
    end
    else begin
      set = {WIDTH{1'b0}};
    end

    get_next_value  = (value & (~i_clear)) | set;
  end
  endfunction
endmodule
