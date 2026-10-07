`timescale 1ns / 1ps
`default_nettype none

module reg_file
  import types::*;
  import isa::*;
(
  input wire logic clk,
  input wire logic rst,
  input wire logic write_en,
  input wire reg_addr_t addr1,
  input wire reg_addr_t addr2,
  input wire reg_addr_t addr3,
  input wire word_t wdata,
  output word_t rdata1,
  output word_t rdata2
);



endmodule

`default_nettype wire
