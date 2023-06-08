module rggen_or_reducer #(
  parameter WIDTH = 1,
  parameter N     = 2
)(
  input   [WIDTH*N-1:0] i_data,
  output  [WIDTH-1:0]   o_result
);
  function automatic [16*N-1:0] get_sub_n_list;
    input integer n;

    reg [15:0]      current_n;
    reg [15:0]      half_n;
    reg [16*N-1:0]  list;
    integer         list_index;
  begin
    current_n   = n[15:0];
    list_index  = 0;
    while (current_n > 0) begin
      half_n  = current_n / 2;
      if ((current_n > 4) && (half_n <= 4)) begin
        list[16*list_index+:16] = half_n;
      end
      else if (current_n >= 4) begin
        list[16*list_index+:16] = 4;
      end
      else begin
        list[16*list_index+:16] = current_n;
      end

      current_n   = current_n - list[16*list_index+:16];
      list_index  = list_index + 1;
    end

    while (list_index < N) begin
      list[16*list_index+:16] = 0;
      list_index              = list_index + 1;
    end

    get_sub_n_list  = list;
  end
  endfunction

  function automatic [16*N-1:0] get_offset_list;
    input [16*N-1:0]  sub_n_list;

    reg [16*N-1:0]  list;
    integer         i;
  begin
    for (i = 0;i < N;i = i + 1) begin
      if (i == 0) begin
        list[16*i+:16]  = 0;
      end
      else begin
        list[16*i+:16]  = sub_n_list[16*(i-1)+:16] + list[16*(i-1)+:16];
      end
    end

    get_offset_list = list;
  end
  endfunction

  function automatic integer get_next_n;
    input [16*N-1:0]  sub_n_list;

    integer next_n;
    integer i;
  begin
    next_n  = 0;
    for (i = 0;i < N;i = i + 1) begin
      next_n  = next_n + ((sub_n_list[16*i+:16] != 0) ? 1 : 0);
    end

    get_next_n  = next_n;
  end
  endfunction

  localparam  [16*N-1:0]  SUB_N_LIST  = get_sub_n_list(N);
  localparam  [16*N-1:0]  OFFSET_LIST = get_offset_list(SUB_N_LIST);
  localparam              NEXT_N      = get_next_n(SUB_N_LIST);

  wire  [WIDTH*NEXT_N-1:0]  next_data;
  genvar                    i;

  generate
    for (i = 0;i < NEXT_N;i = i + 1) begin : g_or_loop
      if (SUB_N_LIST[16*i+:16] == 4) begin : g
        assign  next_data[WIDTH*i+:WIDTH] = (i_data[WIDTH*(OFFSET_LIST[16*i+:16]+0)+:WIDTH] | i_data[WIDTH*(OFFSET_LIST[16*i+:16]+1)+:WIDTH])
                                          | (i_data[WIDTH*(OFFSET_LIST[16*i+:16]+2)+:WIDTH] | i_data[WIDTH*(OFFSET_LIST[16*i+:16]+3)+:WIDTH]);
      end
      else if (SUB_N_LIST[16*i+:16] == 3) begin : g
        assign  next_data[WIDTH*i+:WIDTH] = i_data[WIDTH*(OFFSET_LIST[16*i+:16]+0)+:WIDTH] | i_data[WIDTH*(OFFSET_LIST[16*i+:16]+1)+:WIDTH]
                                          | i_data[WIDTH*(OFFSET_LIST[16*i+:16]+2)+:WIDTH];
      end
      else if (SUB_N_LIST[16*i+:16] == 2) begin : g
        assign  next_data[WIDTH*i+:WIDTH] = i_data[WIDTH*(OFFSET_LIST[16*i+:16]+0)+:WIDTH] | i_data[WIDTH*(OFFSET_LIST[16*i+:16]+1)+:WIDTH];
      end
      else begin : g
        assign  next_data[WIDTH*i+:WIDTH] = i_data[WIDTH*(OFFSET_LIST[16*i+:16]+0)+:WIDTH];
      end
    end

    if (NEXT_N > 1) begin : g_reduce
      rggen_or_reducer #(
        .WIDTH  (WIDTH  ),
        .N      (NEXT_N )
      ) u_reducer (
        .i_data   (next_data  ),
        .o_result (o_result   )
      );
    end
    else begin : g_reduce
      assign  o_result  = next_data[0+:WIDTH];
    end
  endgenerate
endmodule
