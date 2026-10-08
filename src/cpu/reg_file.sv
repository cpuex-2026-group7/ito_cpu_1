`timescale 1ns / 1ps
`default_nettype none

// 非同期read,同期write
module reg_file
  import types::*;
  import isa::*;
(
  input wire logic clk,
  input wire reg_addr_t rd,
  input wire reg_addr_t rs1,
  input wire reg_addr_t rs2,
  input wire logic write_en,
  input wire word_t wdata,
  input wire reg_addr_t r_dbg,
  output word_t rdata1,
  output word_t rdata2,
  output word_t r_dbg_data
);

  word_t regs[64];  // I 32個、F 32個

  initial begin
    for (int i = 0; i < 64; i++) begin
      regs[i] = 0;
    end
  end

  always_ff @(posedge clk) begin
    if (write_en && (rd & 6'b011111)) begin
      regs[rd] <= wdata;
    end
  end

  assign rdata1 = regs[rs1];
  assign rdata1 = regs[rs2];
  assign r_dbg_data = regs[r_dbg];

endmodule

`default_nettype wire
