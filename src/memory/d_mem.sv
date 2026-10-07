`timescale 1ns / 1ps
`default_nettype none

module d_mem
  import types::*;
(
  input wire logic clk,
  input wire logic rst,
  input wire logic write_en,
  input wire addr_t addr,
  input wire word_t wdata,
  output word_t rdata
);

  assign rdata = 32'b0;

endmodule

`default_nettype wire
