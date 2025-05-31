`include  "rggen_rtl_macros.vh"
module rggen_bit_field #(
  parameter WIDTH                     = 8,
  parameter INITIAL_VALUE             = {WIDTH{1'b0}},
  parameter PRECEDENCE_ACCESS         = `RGGEN_HW_ACCESS,
  parameter SW_READ_ACTION            = `RGGEN_READ_DEFAULT,
  parameter SW_WRITE_ACTION           = `RGGEN_WRITE_DEFAULT,
  parameter SW_WRITE_CONTROL          = 1'b0,
  parameter SW_WRITE_ONCE             = 1'b0,
  parameter SW_WRITE_ENABLE_POLARITY  = `RGGEN_ACTIVE_HIGH,
  parameter HW_WRITE_ENABLE_POLARITY  = `RGGEN_ACTIVE_HIGH,
  parameter HW_ACCESS                 = 3'b000,
  parameter HW_SET_WIDTH              = WIDTH,
  parameter HW_CLEAR_WIDTH            = WIDTH,
  parameter STORAGE                   = 1'b1,
  parameter EXTERNAL_READ_DATA        = 1'b0,
  parameter EXTERNAL_MASK             = 1'b0,
  parameter TRIGGER                   = 1'b0
)(
  input                         i_clk,
  input                         i_rst_n,
  input                         i_sw_write_valid,
  input                         i_sw_write_enable,
  input                         i_sw_read_valid,
  input   [WIDTH-1:0]           i_sw_mask,
  input   [WIDTH-1:0]           i_sw_write_data,
  output  [WIDTH-1:0]           o_sw_read_data,
  output  [WIDTH-1:0]           o_sw_value,
  output                        o_write_trigger,
  output                        o_read_trigger,
  input                         i_hw_write_enable,
  input   [WIDTH-1:0]           i_hw_write_data,
  input   [HW_SET_WIDTH-1:0]    i_hw_set,
  input   [HW_CLEAR_WIDTH-1:0]  i_hw_clear,
  input   [WIDTH-1:0]           i_value,
  input   [WIDTH-1:0]           i_mask,
  output  [WIDTH-1:0]           o_value,
  output  [WIDTH-1:0]           o_value_unmasked
);
  localparam  SW_WRITABLE     = SW_WRITE_ACTION != `RGGEN_WRITE_NONE;
  localparam  SW_READABLE     = SW_READ_ACTION  != `RGGEN_READ_NONE;
  localparam  SW_READ_UPDATE  = SW_READABLE && (SW_READ_ACTION != `RGGEN_READ_DEFAULT);

//--------------------------------------------------------------
//  Utility functions
//--------------------------------------------------------------
  function automatic get_sw_write_update;
    input [WIDTH-1:0] write_valid;
    input             write_enable;
    input             write_done;

    reg [2:0] update;
  begin
    update[0] = write_valid;
    if (SW_WRITE_CONTROL) begin
      update[1] = write_enable == SW_WRITE_ENABLE_POLARITY;
    end
    else begin
      update[1] = 1'b1;
    end
    if (SW_WRITE_ONCE) begin
      update[2] = !write_done;
    end
    else begin
      update[2] = 1'b1;
    end

    get_sw_write_update = update[0] && update[1] && update[2];
  end
  endfunction

  function automatic get_hw_update;
    input                       write_enable;
    input [HW_SET_WIDTH-1:0]    set;
    input [HW_CLEAR_WIDTH-1:0]  clear;

    reg [2:0] update;
  begin
    update[0]     = HW_ACCESS[0] && (write_enable == HW_WRITE_ENABLE_POLARITY);
    update[1]     = HW_ACCESS[1] && (set          != {HW_SET_WIDTH{1'b0}}    );
    update[2]     = HW_ACCESS[2] && (clear        != {HW_CLEAR_WIDTH{1'b0}}  );
    get_hw_update = update[0] || update[1] || update[2];
  end
  endfunction

  function automatic [WIDTH-1:0] get_sw_read_next_value;
    input [WIDTH-1:0] current_value;
    input [WIDTH-1:0] mask;

    reg [WIDTH-1:0] value;
  begin
    case (SW_READ_ACTION)
      `RGGEN_READ_CLEAR:  value = (mask != {WIDTH{1'b0}}) ? {WIDTH{1'b0}} : current_value;
      `RGGEN_READ_SET:    value = (mask != {WIDTH{1'b0}}) ? {WIDTH{1'b1}} : current_value;
      default:            value = current_value;
    endcase
    get_sw_read_next_value  = value;
  end
  endfunction

  function automatic [WIDTH-1:0] get_sw_write_next_value;
    input [WIDTH-1:0] current_value;
    input [WIDTH-1:0] mask;
    input [WIDTH-1:0] write_data;

    reg [WIDTH-1:0] value;
    integer         i;
  begin
    value = current_value;
    case (SW_WRITE_ACTION)
      `RGGEN_WRITE_DEFAULT: begin
        for (i = 0;i < WIDTH;i = i + 1) begin
          if (mask[i]) begin
            value[i]  = write_data[i];
          end
        end
      end
      `RGGEN_WRITE_0_CLEAR: begin
        for (i = 0;i < WIDTH;i = i + 1) begin
          if (mask[i] && (!write_data[i])) begin
            value[i]  = 1'b0;
          end
        end
      end
      `RGGEN_WRITE_1_CLEAR: begin
        for (i = 0;i < WIDTH;i = i + 1) begin
          if (mask[i] && write_data[i]) begin
            value[i]  = 1'b0;
          end
        end
      end
      `RGGEN_WRITE_CLEAR: begin
        if (mask != {WIDTH{1'b0}}) begin
          value = {WIDTH{1'b0}};
        end
      end
      `RGGEN_WRITE_0_SET: begin
        for (i = 0;i < WIDTH;i = i + 1) begin
          if (mask[i] && (!write_data[i])) begin
            value[i]  = 1'b1;
          end
        end
      end
      `RGGEN_WRITE_1_SET: begin
        for (i = 0;i < WIDTH;i = i + 1) begin
          if (mask[i] && write_data[i]) begin
            value[i]  = 1'b1;
          end
        end
      end
      `RGGEN_WRITE_SET: begin
        if (mask != {WIDTH{1'b0}}) begin
          value = {WIDTH{1'b1}};
        end
      end
      `RGGEN_WRITE_0_TOGGLE: begin
        for (i = 0;i < WIDTH;i = i + 1) begin
          if (mask[i] && (!write_data[i])) begin
            value[i]  = ~current_value[i];
          end
        end
      end
      `RGGEN_WRITE_1_TOGGLE: begin
        for (i = 0;i < WIDTH;i = i + 1) begin
          if (mask[i] && write_data[i]) begin
            value[i]  = ~current_value[i];
          end
        end
      end
      default: ;
    endcase

    get_sw_write_next_value = value;
  end
  endfunction

  function automatic [WIDTH-1:0] get_hw_next_value;
    input [WIDTH-1:0]           current_value;
    input                       write_enable;
    input [WIDTH-1:0]           write_data;
    input [HW_SET_WIDTH-1:0]    set;
    input [HW_CLEAR_WIDTH-1:0]  clear;

    reg [WIDTH-1:0] set_clear[0:1];
    reg [WIDTH-1:0] value;
    integer         i;
  begin
    if (!HW_ACCESS[1]) begin
      set_clear[0]  = {WIDTH{1'b0}};
    end
    else if (HW_SET_WIDTH == WIDTH) begin
      set_clear[0][HW_SET_WIDTH-1:0]  = set;
    end
    else begin
      set_clear[0]  = {WIDTH{set[0]}};
    end

    if (!HW_ACCESS[2]) begin
      set_clear[1]  = {WIDTH{1'b0}};
    end
    else if (HW_CLEAR_WIDTH == WIDTH) begin
      set_clear[1][HW_CLEAR_WIDTH-1:0]  = clear;
    end
    else begin
      set_clear[1]  = {WIDTH{clear[0]}};
    end

    for (i = 0;i < WIDTH;i = i + 1) begin
      if (set_clear[0][i]) begin
        value[i]  = 1'b1;
      end
      else if (set_clear[1][i]) begin
        value[i]  = 1'b0;
      end
      else if (HW_ACCESS[0] && (write_enable == HW_WRITE_ENABLE_POLARITY)) begin
        value[i]  = write_data[i];
      end
      else begin
        value[i]  = current_value[i];
      end
    end

    get_hw_next_value = value;
  end
  endfunction

//--------------------------------------------------------------
//  Body
//--------------------------------------------------------------
  wire  [1:0]       w_sw_update;
  wire              w_sw_write_done;
  wire              w_hw_update;
  wire  [1:0]       w_trigger;
  wire  [WIDTH-1:0] w_read_data;
  wire  [WIDTH-1:0] w_value;

  assign  o_sw_read_data    = (EXTERNAL_MASK) ? w_read_data & i_mask : w_read_data;
  assign  o_sw_value        = w_value;
  assign  o_write_trigger   = w_trigger[0];
  assign  o_read_trigger    = w_trigger[1];
  assign  o_value           = (EXTERNAL_MASK) ? w_value & i_mask : w_value;
  assign  o_value_unmasked  = w_value;

  generate
    if (SW_READ_UPDATE) begin : g_sw_read_update
      assign  w_sw_update[0]  = i_sw_read_valid;
    end
    else begin : g_sw_read_update
      assign  w_sw_update[0]  = 1'b0;
    end

    if (SW_WRITABLE) begin : g_sw_write_update
      assign  w_sw_update[1]  = get_sw_write_update(i_sw_write_valid, i_sw_write_enable, w_sw_write_done);
    end
    else begin : g_sw_write_update
      assign  w_sw_update[1]  = 1'b0;
    end

    if (HW_ACCESS != 3'b000) begin : g_hw_update
      assign  w_hw_update = get_hw_update(i_hw_write_enable, i_hw_set, i_hw_clear);
    end
    else begin
      assign  w_hw_update = 1'b0;
    end
  endgenerate

  generate
    if (STORAGE && SW_WRITABLE && SW_WRITE_ONCE) begin : g_sw_write_done
      reg r_sw_write_done;

      assign  w_sw_write_done = r_sw_write_done;
      always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
          r_sw_write_done <= 1'b0;
        end
        else if (w_sw_update[1] && (i_sw_mask != {WIDTH{1'b0}})) begin
          r_sw_write_done <= 1'b1;
        end
      end
    end
    else begin : g_sw_write_done
      assign  w_sw_write_done = 1'b0;
    end
  endgenerate

  generate
    if (TRIGGER && SW_WRITABLE) begin : g_write_trigger
      reg r_trigger;

      assign  w_trigger[0]  = r_trigger;
      always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
          r_trigger <= 1'b0;
        end
        else begin
          r_trigger <= w_sw_update[1] && (i_sw_mask != {WIDTH{1'b0}});
        end
      end
    end
    else begin : g_write_trigger
      assign  w_trigger[0]  = 1'b0;
    end

    if (TRIGGER && SW_READABLE) begin : g_read_trigger
      reg r_trigger;

      assign  w_trigger[1]  = r_trigger;
      always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
          r_trigger <= 1'b0;
        end
        else begin
          r_trigger <= i_sw_read_valid && (i_mask != {WIDTH{1'b0}});
        end
      end
    end
    else begin : g_read_trigger
      assign  w_trigger[1]  = 1'b0;
    end
  endgenerate

  generate
    if (!STORAGE) begin : g_value
      assign  w_value = i_value;
    end
    else if (PRECEDENCE_ACCESS == `RGGEN_SW_ACCESS) begin : g_value
      reg [WIDTH-1:0] r_value;

      assign  w_value = r_value;
      always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
          r_value <= INITIAL_VALUE;
        end
        else if (SW_READ_UPDATE && w_sw_update[0]) begin
          r_value <=
            get_sw_read_next_value(r_value, i_sw_mask);
        end
        else if (SW_WRITABLE && w_sw_update[1]) begin
          r_value <=
            get_sw_write_next_value(r_value, i_sw_mask, i_sw_write_data);
        end
        else if ((HW_ACCESS != 3'b000) && w_hw_update) begin
          r_value <=
            get_hw_next_value(
              r_value, i_hw_write_enable, i_sw_write_data,
              i_hw_set, i_hw_clear
            );
        end
      end
    end
    else begin : g_value
      reg [WIDTH-1:0] r_value;

      assign  w_value = r_value;
      always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
          r_value <= INITIAL_VALUE;
        end
        else if ((HW_ACCESS != 3'b000) && w_hw_update) begin
          r_value <=
            get_hw_next_value(
              r_value, i_hw_write_enable, i_sw_write_data,
              i_hw_set, i_hw_clear
            );
        end
        else if (SW_READ_UPDATE && w_sw_update[0]) begin
          r_value <=
            get_sw_read_next_value(r_value, i_sw_mask);
        end
        else if (SW_WRITABLE && w_sw_update[1]) begin
          r_value <=
            get_sw_write_next_value(r_value, i_sw_mask, i_sw_write_data);
        end
      end
    end
  endgenerate

  generate
    if (!SW_READABLE) begin : g_read_data
      assign  w_read_data = {WIDTH{1'b0}};
    end
    else if (EXTERNAL_READ_DATA) begin : g_read_data
      assign  w_read_data = i_value;
    end
    else begin : g_read_data
      assign  w_read_data = w_value;
    end
  endgenerate
endmodule
