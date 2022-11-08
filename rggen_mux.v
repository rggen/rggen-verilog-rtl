module rggen_mux #(
  parameter WIDTH   = 1,
  parameter ENTRIES = 2
)(
  input   [ENTRIES-1:0]       i_select,
  input   [WIDTH*ENTRIES-1:0] i_data,
  output  [WIDTH-1:0]         o_data
);
  generate
    if (ENTRIES >= 2) begin : g
      wire  [WIDTH*ENTRIES-1:0] masked_data;
      genvar                    i;

      for (i = 0;i < ENTRIES;i = i + 1) begin : g
        assign  masked_data[WIDTH*i+:WIDTH] = i_data[WIDTH*i+:WIDTH] & {WIDTH{i_select[i]}};
      end

      rggen_or_reducer #(
        .WIDTH  (WIDTH    ),
        .N      (ENTRIES  )
      ) u_reducer (
        .i_data   (masked_data  ),
        .o_result (o_data       )
      );
    end
    else begin : g
      assign  o_data  = i_data;
    end
  endgenerate
endmodule
