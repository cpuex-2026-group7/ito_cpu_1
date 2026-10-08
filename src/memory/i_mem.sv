`timescale 1ns / 1ps
`default_nettype none

module i_mem
  import types::*;
  import isa::*;
(
  input wire addr_t addr,
  output instr_t instr
);

  word_t mem[1024];
  initial $readmemh("fib.mem", mem);
  assign instr = mem[addr[9:0]];

endmodule

`default_nettype wire
