`include "rggen_rtl_macros.vh"
module rggen_bit_field_counter #(
  parameter WIDTH           = 8,
  parameter INITIAL_VALUE   = {WIDTH{1'b0}},
  parameter UP_WIDTH        = 1,
  parameter DOWN_WIDTH      = 1,
  parameter WRAP_AROUND     = 0,
  parameter USE_CLEAR       = 1,
  parameter UP_PORT_WIDTH   = `rggen_clip_width(UP_WIDTH),
  parameter DOWN_PORT_WIDTH = `rggen_clip_width(DOWN_WIDTH)
)(
  input                         i_clk,
  input                         i_rst_n,
  input                         i_sw_write_valid,
  input                         i_sw_read_valid,
  input   [WIDTH-1:0]           i_sw_mask,
  input   [WIDTH-1:0]           i_sw_write_data,
  output  [WIDTH-1:0]           o_sw_read_data,
  output  [WIDTH-1:0]           o_sw_value,
  input                         i_clear,
  input   [UP_PORT_WIDTH-1:0]   i_up,
  input   [DOWN_PORT_WIDTH-1:0] i_down,
  output  [WIDTH-1:0]           o_count
);
  reg   [WIDTH-1:0]           r_count;
  wire  [UP_PORT_WIDTH-1:0]   w_up;
  wire  [DOWN_PORT_WIDTH-1:0] w_down;
  integer                     i;

  assign  o_sw_read_data  = r_count;
  assign  o_sw_value      = r_count;
  assign  o_count         = r_count;

  assign  w_up    = (UP_WIDTH   > 0) ? i_up   : {UP_PORT_WIDTH{1'b0}};
  assign  w_down  = (DOWN_WIDTH > 0) ? i_down : {DOWN_PORT_WIDTH{1'b0}};

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_count <= INITIAL_VALUE;
    end
    else if (USE_CLEAR && i_clear) begin
      r_count <= INITIAL_VALUE;
    end
    else if (i_sw_write_valid) begin
      for (i = 0;i < WIDTH;i = i + 1) begin
        if (i_sw_mask[i]) begin
          r_count[i]  <= i_sw_write_data[i];
        end
      end
    end
    else if ((w_up != {UP_PORT_WIDTH{1'b0}}) || (w_down != {DOWN_PORT_WIDTH{1'b0}})) begin
      if (WRAP_AROUND) begin
        r_count <= calc_count_next_simple(r_count, w_up, w_down);
      end
      else begin
        r_count <= calc_count_next(r_count, w_up, w_down);
      end
    end
  end

  `include  "rggen_clog2.vh"

  localparam  UP_VALUE_WIDTH    = `rggen_clip_width(clog2(UP_WIDTH + 1));
  localparam  DOWN_VALUE_WIDTH  = `rggen_clip_width(clog2(DOWN_WIDTH + 1));

  function automatic [WIDTH-1:0] calc_count_next_simple;
    input [WIDTH-1:0]           count;
    input [UP_PORT_WIDTH-1:0]   up;
    input [DOWN_PORT_WIDTH-1:0] down;

    reg [UP_VALUE_WIDTH-1:0]    up_value;
    reg [UP_VALUE_WIDTH-1:0]    up_1;
    reg [DOWN_VALUE_WIDTH-1:0]  down_value;
    reg [DOWN_VALUE_WIDTH-1:0]  down_1;
    integer                     i;
  begin
    up_1      = {UP_VALUE_WIDTH{1'b0}};
    up_1[0]   = 1'b1;
    up_value  = {UP_VALUE_WIDTH{1'b0}};
    for (i = 0;i < UP_WIDTH;i = i + 1) begin
      if (up[i]) begin
        up_value  = up_value + up_1;
      end
    end

    down_1      = {DOWN_VALUE_WIDTH{1'b0}};
    down_1[0]   = 1'b1;
    down_value  = {DOWN_VALUE_WIDTH{1'b0}};
    for (i = 0;i < DOWN_WIDTH;i = i + 1) begin
      if (down[i]) begin
        down_value  = down_value + down_1;
      end
    end

    calc_count_next_simple  =
      count
      + {{{(WIDTH-UP_VALUE_WIDTH){1'b0}}}, up_value}
      - {{{(WIDTH-DOWN_VALUE_WIDTH){1'b0}}}, down_value};
  end
  endfunction

  localparam  UP_DOWN_WIDTH       = (UP_WIDTH > DOWN_WIDTH) ? UP_WIDTH : DOWN_WIDTH;
  localparam  UP_DOWN_VALUE_WIDTH = `rggen_clip_width(clog2(UP_DOWN_WIDTH + 1)) + 1;
  localparam  COUNT_NEXT_WIDTH    = WIDTH + 1;
  localparam  MAX_VALUE           = {WIDTH{1'b1}};
  localparam  MIN_VALUE           = {WIDTH{1'b0}};

  function automatic [WIDTH-1:0] calc_count_next;
    input [WIDTH-1:0]           count;
    input [UP_PORT_WIDTH-1:0]   up;
    input [DOWN_PORT_WIDTH-1:0] down;

    reg [1:0]                     up_down;
    reg [UP_DOWN_VALUE_WIDTH-1:0] up_down_value;
    reg [UP_DOWN_VALUE_WIDTH-1:0] up_down_1;
    reg [COUNT_NEXT_WIDTH-1:0]    count_next;
    integer                       i;
  begin
    up_down_1     = {UP_DOWN_VALUE_WIDTH{1'b0}};
    up_down_1[0]  = 1'b1;
    up_down_value = {UP_DOWN_VALUE_WIDTH{1'b0}};
    for (i = 0;i < UP_DOWN_WIDTH;i = i + 1) begin
      up_down[1]  = (i < UP_WIDTH  ) && up[i];
      up_down[0]  = (i < DOWN_WIDTH) && down[i];

      case (up_down)
        2'b10:    up_down_value = up_down_value + up_down_1;
        2'b01:    up_down_value = up_down_value - up_down_1;
        default:  up_down_value = up_down_value;
      endcase
    end

    count_next  =
      {1'b0, count}
      + {{(COUNT_NEXT_WIDTH-UP_DOWN_VALUE_WIDTH){up_down_value[UP_DOWN_VALUE_WIDTH-1]}}, up_down_value};
    if (!count_next[COUNT_NEXT_WIDTH-1]) begin
      calc_count_next = count_next[0+:WIDTH];
    end
    else if (up_down_value[UP_DOWN_VALUE_WIDTH-1]) begin
      // underflow
      calc_count_next = MIN_VALUE;
    end
    else begin
      //  overflow
      calc_count_next = MAX_VALUE;
    end
  end
  endfunction
endmodule
