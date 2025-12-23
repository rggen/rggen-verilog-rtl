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
