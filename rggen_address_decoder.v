module rggen_address_decoder #(
  parameter READABLE      = 1'b1,
  parameter WRITABLE      = 1'b1,
  parameter WIDTH         = 8,
  parameter BUS_WIDTH     = 32,
  parameter START_ADDRESS = {WIDTH{1'b0}},
  parameter BYTE_SIZE     = 0
)(
  input   [WIDTH-1:0] i_address,
  input   [1:0]       i_access,
  input               i_additional_match,
  output              o_match
);
  localparam                  LSB                 = clog2(BUS_WIDTH) - 3;
  localparam                  ACCESS_BIT          = 0;
  localparam  [WIDTH-LSB-1:0] BEGIN_ADDRESS       = START_ADDRESS[WIDTH-1:LSB];
  localparam  [WIDTH-LSB-1:0] END_ADDRESS         = calc_end_address(START_ADDRESS[WIDTH-1:0], BYTE_SIZE);
  localparam                  BEGIN_ADDRESS_ALL_0 = BEGIN_ADDRESS == {(WIDTH-LSB){1'b0}};
  localparam                  END_ADDRESS_ALL_1   = END_ADDRESS   == {(WIDTH-LSB){1'b1}};

  function automatic integer clog2;
    input integer n;

    integer result;
    integer value;
  begin
    value   = n - 1;
    result  = 0;
    while (value > 0) begin
      result  = result + 1;
      value   = value >> 1;
    end
    clog2 = result;
  end
  endfunction

  function automatic [WIDTH-LSB-1:0] calc_end_address;
    input [WIDTH-1:0] start_address;
    input integer     byte_size;

    reg [WIDTH-1:0] address;
    integer         delta;
  begin
    delta             = byte_size - 1;
    address           = start_address + delta[WIDTH-1:0];
    calc_end_address  = address[WIDTH-1:LSB];
  end
  endfunction

  wire  w_address_match;
  wire  w_access_match;

  assign  o_match = w_address_match && w_access_match && i_additional_match;

  generate
    if (BEGIN_ADDRESS == END_ADDRESS) begin : g_address_match
      assign  w_address_match = i_address[WIDTH-1:LSB] == BEGIN_ADDRESS;
    end
    else if ((!BEGIN_ADDRESS_ALL_0) && (!END_ADDRESS_ALL_1)) begin : g_address_match
      assign  w_address_match =
        (i_address[WIDTH-1:LSB] >= BEGIN_ADDRESS) &&
        (i_address[WIDTH-1:LSB] <= END_ADDRESS  );
    end
    else if ((!BEGIN_ADDRESS_ALL_0) && END_ADDRESS_ALL_1) begin : g_address_match
      assign  w_address_match = i_address[WIDTH-1:LSB] >= BEGIN_ADDRESS;
    end
    else if (BEGIN_ADDRESS_ALL_0 && (!END_ADDRESS_ALL_1)) begin : g_address_match
      assign  w_address_match = i_address[WIDTH-1:LSB] <= END_ADDRESS;
    end
    else begin : g_address_match
      assign  w_address_match = 1'b1;
    end

    if (READABLE && WRITABLE) begin : g_access_match
      assign  w_access_match  = 1'b1;
    end
    else if (READABLE) begin : g_access_match
      assign  w_access_match  = i_access[ACCESS_BIT] == 1'b0;
    end
    else begin : g_access_match
      assign  w_access_match  = i_access[ACCESS_BIT] == 1'b1;
    end
  endgenerate
endmodule
