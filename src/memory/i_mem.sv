`timescale 1ns / 1ps
`default_nettype none

module i_mem
  import types::*;
(
  input wire addr_t addr,
  output instr_t instr
);

  assign instr = 32'b0;

endmodule

`default_nettype wire
