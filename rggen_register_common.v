`include  "rggen_rtl_macros.vh"
module rggen_register_common #(
  parameter READABLE              = 1'b1,
  parameter WRITABLE              = 1'b1,
  parameter ADDRESS_WIDTH         = 8,
  parameter OFFSET_ADDRESS        = {ADDRESS_WIDTH{1'b0}},
  parameter BUS_WIDTH             = 32,
  parameter DATA_WIDTH            = BUS_WIDTH,
  parameter USE_ADDITIONAL_MATCH  = 1'b0
)(
  input                       i_clk,
  input                       i_rst_n,
  input                       i_register_valid,
  input   [1:0]               i_register_access,
  input   [ADDRESS_WIDTH-1:0] i_register_address,
  input   [BUS_WIDTH-1:0]     i_register_write_data,
  input   [BUS_WIDTH-1:0]     i_register_strobe,
  output                      o_register_active,
  output                      o_register_ready,
  output  [1:0]               o_register_status,
  output  [BUS_WIDTH-1:0]     o_register_read_data,
  output  [DATA_WIDTH-1:0]    o_register_value,
  input                       i_additional_match,
  output                      o_bit_field_write_valid,
  output                      o_bit_field_read_valid,
  output  [DATA_WIDTH-1:0]    o_bit_field_mask,
  output  [DATA_WIDTH-1:0]    o_bit_field_write_data,
  input   [DATA_WIDTH-1:0]    i_bit_field_read_data,
  input   [DATA_WIDTH-1:0]    i_bit_field_value
);
  localparam  WORDS           = DATA_WIDTH / BUS_WIDTH;
  localparam  BUS_BYTE_WIDTH  = BUS_WIDTH / 8;
  localparam  DATA_BYTE_WIDTH = DATA_WIDTH / 8;

  genvar  g_i;

  //  Decode address
  wire  [WORDS-1:0] w_match;
  wire              w_active;

  generate
    for (g_i = 0;g_i < WORDS;g_i = g_i + 1) begin : g_decoder
      rggen_address_decoder #(
        .READABLE             (READABLE                 ),
        .WRITABLE             (WRITABLE                 ),
        .WIDTH                (ADDRESS_WIDTH            ),
        .BUS_WIDTH            (BUS_WIDTH                ),
        .START_ADDRESS        (calc_start_address(g_i)  ),
        .BYTE_SIZE            (BUS_BYTE_WIDTH           ),
        .USE_ADDITIONAL_MATCH (USE_ADDITIONAL_MATCH     )
      ) u_decoder (
        .i_address          (i_register_address ),
        .i_access           (i_register_access  ),
        .i_additional_match (i_additional_match ),
        .o_match            (w_match[g_i]       )
      );
    end

    if (WORDS == 1) begin : g_match
      assign  w_active  = w_match[0];
    end
    else begin : g_match
      assign  w_active  = |w_match;
    end
  endgenerate

  function automatic [ADDRESS_WIDTH-1:0] calc_start_address;
    input integer index;

    reg [ADDRESS_WIDTH-1:0] offset_address;
    integer                 delta;
  begin
    offset_address      = OFFSET_ADDRESS[ADDRESS_WIDTH-1:0];
    delta               = BUS_BYTE_WIDTH * index;
    calc_start_address  = offset_address + delta[ADDRESS_WIDTH-1:0];
  end
  endfunction

  //  Request
  wire                    w_frontdoor_valid;
  wire                    w_backdoor_valid;
  wire                    w_pending_valid;
  wire  [DATA_WIDTH-1:0]  w_mask[0:1];
  wire                    w_write[0:1];
  wire  [DATA_WIDTH-1:0]  w_write_data[0:1];

  assign  o_bit_field_write_valid = ((w_frontdoor_valid || w_pending_valid) &&   w_write[0] ) || (w_backdoor_valid &&   w_write[1] );
  assign  o_bit_field_read_valid  = ((w_frontdoor_valid || w_pending_valid) && (!w_write[0])) || (w_backdoor_valid && (!w_write[1]));
  assign  o_bit_field_mask        = (w_backdoor_valid) ? w_mask[1]       : w_mask[0];
  assign  o_bit_field_write_data  = (w_backdoor_valid) ? w_write_data[1] : w_write_data[0];

  assign  w_frontdoor_valid = i_register_valid && w_active;
  assign  w_write[0]        = i_register_access[0];
  assign  w_mask[0]         = get_mask(w_match, i_register_strobe);
  assign  w_write_data[0]   = {WORDS{i_register_write_data}};

  function automatic [DATA_WIDTH-1:0] get_mask;
    input [WORDS-1:0]     match;
    input [BUS_WIDTH-1:0] strobe;

    integer               i;
    reg [DATA_WIDTH-1:0]  mask;
  begin
    if (BUS_WIDTH == DATA_WIDTH) begin
      mask  = strobe;
    end
    else begin
      for (i = 0;i < WORDS;i = i + 1) begin
        if (match[i]) begin
          mask[BUS_WIDTH*i+:BUS_WIDTH]  = strobe;
        end
        else begin
          mask[BUS_WIDTH*i+:BUS_WIDTH]  = {BUS_WIDTH{1'b0}};
        end
      end
    end

    get_mask  = mask;
  end
  endfunction

  //  Response
  wire  [BUS_WIDTH-1:0]   w_read_data;

  assign  o_register_active     = w_active;
  assign  o_register_ready      = !w_backdoor_valid;
  assign  o_register_status     = 2'b00;
  assign  o_register_read_data  = w_read_data;
  assign  o_register_value      = i_bit_field_value;

  rggen_mux #(
    .WIDTH    (BUS_WIDTH  ),
    .ENTRIES  (WORDS      )
  ) u_read_data_mux (
    .i_select (w_match                ),
    .i_data   (i_bit_field_read_data  ),
    .o_data   (w_read_data            )
  );

`ifdef RGGEN_ENABLE_BACKDOOR
  //  Backdoor access
  rggen_backdoor #(
    .DATA_WIDTH (DATA_WIDTH )
  ) u_backdoor (
    .i_clk              (i_clk                  ),
    .i_rst_n            (i_rst_n                ),
    .i_frontdoor_valid  (w_frontdoor_valid      ),
    .i_frontdoor_ready  (o_register_ready       ),
    .o_backdoor_valid   (w_backdoor_valid       ),
    .o_pending_valid    (w_pending_valid        ),
    .o_write            (w_write[1]             ),
    .o_mask             (w_mask[1]              ),
    .o_write_data       (w_write_data[1]        ),
    .i_read_data        (i_bit_field_read_data  ),
    .i_value            (i_bit_field_value      )
  );
`else
  assign  w_backdoor_valid  = 1'b0;
  assign  w_pending_valid   = 1'b0;
  assign  w_write[1]        = 1'b0;
  assign  w_mask[1]         = {BUS_WIDTH{1'b0}};
  assign  w_write_data[1]   = {BUS_WIDTH{1'b0}};
`endif
endmodule
