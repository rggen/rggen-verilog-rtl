`include  "rggen_rtl_macros.vh"
module rggen_adapter_common #(
  parameter ADDRESS_WIDTH       = 8,
  parameter LOCAL_ADDRESS_WIDTH = 8,
  parameter BUS_WIDTH           = 32,
  parameter STROBE_WIDTH        = BUS_WIDTH / 8,
  parameter REGISTERS           = 1,
  parameter PRE_DECODE          = 0,
  parameter BASE_ADDRESS        = {ADDRESS_WIDTH{1'b0}},
  parameter BYTE_SIZE           = 256,
  parameter USE_READ_STROBE     = 0,
  parameter ERROR_STATUS        = 0,
  parameter DEFAULT_READ_DATA   = {BUS_WIDTH{1'b0}},
  parameter INSERT_SLICER       = 0
)(
  input                             i_clk,
  input                             i_rst_n,
  input                             i_bus_valid,
  input   [1:0]                     i_bus_access,
  input   [ADDRESS_WIDTH-1:0]       i_bus_address,
  input   [BUS_WIDTH-1:0]           i_bus_write_data,
  input   [STROBE_WIDTH-1:0]        i_bus_strobe,
  output                            o_bus_ready,
  output  [1:0]                     o_bus_status,
  output  [BUS_WIDTH-1:0]           o_bus_read_data,
  output                            o_register_valid,
  output  [1:0]                     o_register_access,
  output  [LOCAL_ADDRESS_WIDTH-1:0] o_register_address,
  output  [BUS_WIDTH-1:0]           o_register_write_data,
  output  [BUS_WIDTH-1:0]           o_register_strobe,
  input   [REGISTERS-1:0]           i_register_active,
  input   [REGISTERS-1:0]           i_register_ready,
  input   [2*REGISTERS-1:0]         i_register_status,
  input   [BUS_WIDTH*REGISTERS-1:0] i_register_read_data
);
  localparam  RESPONSE_WIDTH  = 1 + 1 + BUS_WIDTH + ((ERROR_STATUS) ? 1 : 0);

  genvar                                i;
  reg                                   r_busy;
  wire                                  w_inside_range;
  wire  [RESPONSE_WIDTH*REGISTERS-1:0]  w_response;
  wire  [RESPONSE_WIDTH-1:0]            w_register_response;
  wire                                  w_register_active;
  wire                                  w_register_ready;
  wire                                  w_register_inactive;
  wire  [1:0]                           w_register_status;
  wire  [BUS_WIDTH-1:0]                 w_register_read_data;
  wire                                  w_bus_ready;

  //  State
  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_busy  <= 1'b0;
    end
    else if (w_bus_ready) begin
      r_busy  <= 1'b0;
    end
    else if (i_bus_valid) begin
      r_busy  <= 1'b1;
    end
  end

  //  Pre decode
  assign  w_inside_range  = (PRE_DECODE != 0) ? pre_decode(i_bus_address) : 1'b1;

  function automatic pre_decode;
    input [ADDRESS_WIDTH-1:0] address;

    integer                 delta;
    reg [ADDRESS_WIDTH-1:0] begin_address;
    reg [ADDRESS_WIDTH-1:0] end_address;
  begin
    delta         = BYTE_SIZE - 1;
    begin_address = BASE_ADDRESS[ADDRESS_WIDTH-1:0];
    end_address   = begin_address + delta[ADDRESS_WIDTH-1:0];
    pre_decode    = (address >= begin_address) && (address <= end_address);
  end
  endfunction

  //  Request
  generate
    if (INSERT_SLICER) begin : g_request_slicer
      reg                           r_bus_valid;
      reg [1:0]                     r_bus_access;
      reg [LOCAL_ADDRESS_WIDTH-1:0] r_bus_address;
      reg [BUS_WIDTH-1:0]           r_bus_write_data;
      reg [STROBE_WIDTH-1:0]        r_bus_strobe;

      assign  o_register_valid      = r_bus_valid;
      assign  o_register_access     = r_bus_access;
      assign  o_register_address    = r_bus_address;
      assign  o_register_write_data = r_bus_write_data;
      assign  o_register_strobe     = get_register_strobe(r_bus_access, r_bus_strobe);

      always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
          r_bus_valid <= 1'b0;
        end
        else if (!r_busy) begin
          r_bus_valid <= i_bus_valid && w_inside_range;
        end
        else begin
          r_bus_valid <= 1'b0;
        end
      end

      always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
          r_bus_access      <= 2'b00;
          r_bus_address     <= {LOCAL_ADDRESS_WIDTH{1'b0}};
          r_bus_write_data  <= {BUS_WIDTH{1'b0}};
          r_bus_strobe      <= {STROBE_WIDTH{1'b0}};
        end
        else begin
          r_bus_access      <= i_bus_access;
          r_bus_address     <= get_local_address(i_bus_address);
          r_bus_write_data  <= i_bus_write_data;
          r_bus_strobe      <= i_bus_strobe;
        end
      end
    end
    else begin : g_no_request_slicer
      assign  o_register_valid      = i_bus_valid && w_inside_range && (!r_busy);
      assign  o_register_access     = i_bus_access;
      assign  o_register_address    = get_local_address(i_bus_address);
      assign  o_register_write_data = i_bus_write_data;
      assign  o_register_strobe     = get_register_strobe(i_bus_access, i_bus_strobe);
    end
  endgenerate

  function automatic [LOCAL_ADDRESS_WIDTH-1:0] get_local_address;
    input [ADDRESS_WIDTH-1:0] address;

    reg [ADDRESS_WIDTH-1:0] local_address;
  begin
    if (BASE_ADDRESS[0+:LOCAL_ADDRESS_WIDTH] == {LOCAL_ADDRESS_WIDTH{1'b0}}) begin
      local_address = address;
    end
    else begin
      local_address = address - BASE_ADDRESS;
    end

    get_local_address = local_address[0+:LOCAL_ADDRESS_WIDTH];
  end
  endfunction

  function automatic [BUS_WIDTH-1:0] get_register_strobe;
    input [1:0]               access;
    input [STROBE_WIDTH-1:0]  strobe;

    reg [BUS_WIDTH-1:0] register_strobe;
    integer             i;
  begin
    if ((!USE_READ_STROBE) && (access == `RGGEN_READ)) begin
      register_strobe = {BUS_WIDTH{1'b1}};
    end
    else if (BUS_WIDTH == STROBE_WIDTH) begin
      register_strobe[STROBE_WIDTH-1:0] = strobe;
    end
    else begin
      for (i = 0;i < STROBE_WIDTH;i = i + 1) begin
        register_strobe[8*i+:8] = {8{strobe[i]}};
      end
    end

    get_register_strobe = register_strobe;
  end
  endfunction

  //  Response
  generate
    if (ERROR_STATUS) begin : g_response
      for (i = 0;i < REGISTERS;i = i + 1) begin : g
        assign  w_response[RESPONSE_WIDTH*i+:RESPONSE_WIDTH]  = {
          i_register_status[2*i+:2],
          i_register_read_data[BUS_WIDTH*i+:BUS_WIDTH],
          i_register_ready[i],
          1'b1
        };
      end

      assign  w_register_status     = w_register_response[2+BUS_WIDTH+:2];
      assign  w_register_read_data  = w_register_response[2+:BUS_WIDTH];
      assign  w_register_ready      = w_register_response[1];
      assign  w_register_active     = w_register_response[0];
    end
    else begin : g_reponse
      for (i = 0;i < REGISTERS;i = i + 1) begin : g
        assign  w_response[RESPONSE_WIDTH*i+:RESPONSE_WIDTH]  = {
          i_register_read_data[BUS_WIDTH*i+:BUS_WIDTH],
          i_register_ready[i],
          1'b1
        };
      end

      assign  w_register_status     = `RGGEN_OKAY;
      assign  w_register_read_data  = w_register_response[2+:BUS_WIDTH];
      assign  w_register_ready      = w_register_response[1];
      assign  w_register_active     = w_register_response[0];
    end
  endgenerate

  rggen_mux #(
    .WIDTH    (RESPONSE_WIDTH ),
    .ENTRIES  (REGISTERS      )
  ) u_response_mux (
    .i_select (i_register_active    ),
    .i_data   (w_response           ),
    .o_data   (w_register_response  )
  );

  assign  o_bus_ready     = w_bus_ready;
  assign  o_bus_status    = (ERROR_STATUS && w_register_inactive) ? `RGGEN_SLAVE_ERROR : w_register_status;
  assign  o_bus_read_data = (ERROR_STATUS && w_register_inactive) ? DEFAULT_READ_DATA  : w_register_read_data;

  assign  w_register_inactive = (!w_register_active) || (!w_inside_range);
  generate
    if (INSERT_SLICER) begin : g_response_ready
      assign  w_bus_ready = r_busy && (w_register_ready || w_register_inactive);
    end
    else begin : g_response_ready
      assign  w_bus_ready = w_register_ready || w_register_inactive;
    end
  endgenerate
endmodule
