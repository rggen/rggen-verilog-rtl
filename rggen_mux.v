module rggen_mux #(
  parameter WIDTH   = 1,
  parameter ENTRIES = 2
)(
  input   [ENTRIES-1:0]       i_select,
  input   [WIDTH*ENTRIES-1:0] i_data,
  output  [WIDTH-1:0]         o_data
);
  function automatic [WIDTH-1:0] mux;
    input [ENTRIES-1:0]       select;
    input [WIDTH*ENTRIES-1:0] in;

    integer                 i, j;
    reg [ENTRIES*WIDTH-1:0] temp;
  begin
    for (i = 0;i < WIDTH;i = i + 1) begin
      for (j = 0;j < ENTRIES;j = j + 1) begin
        temp[ENTRIES*i+j] = select[j] & in[WIDTH*j+i];
      end
      mux[i]  = |temp[ENTRIES*i+:ENTRIES];
    end
  end
  endfunction

  generate if (ENTRIES == 1) begin : g
    assign  o_data  = i_data;
  end
  else begin : g
    assign  o_data  = mux(i_select, i_data);
  end endgenerate
endmodule
