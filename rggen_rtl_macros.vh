`ifndef RGGEN_RTL_MACRO_VH
`define RGGEN_RTL_MACRO_VH

`define RGGEN_SW_ACCESS 0
`define RGGEN_HW_ACCESS 1

`define RGGEN_ACTIVE_LOW  1'b0
`define RGGEN_ACTIVE_HIGH 1'b1

`define RGGEN_READ_NONE     0
`define RGGEN_READ_DEFAULT  1
`define RGGEN_READ_CLEAR    2
`define RGGEN_READ_SET      3

`define RGGEN_WRITE_NONE      0
`define RGGEN_WRITE_DEFAULT   1
`define RGGEN_WRITE_0_CLEAR   2
`define RGGEN_WRITE_1_CLEAR   3
`define RGGEN_WRITE_CLEAR     4
`define RGGEN_WRITE_0_SET     5
`define RGGEN_WRITE_1_SET     6
`define RGGEN_WRITE_SET       7
`define RGGEN_WRITE_0_TOGGLE  8
`define RGGEN_WRITE_1_TOGGLE  9

`define rggen_slice(EXPRESSION, WIDTH, INDEX) \
(((EXPRESSION) >> ((WIDTH) * (INDEX))) & {(WIDTH){1'b1}})

`endif
