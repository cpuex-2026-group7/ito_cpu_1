`timescale 1ns / 1ps
`default_nettype none

module alu
  import types::*;
  import isa::*;
(
  input wire word_t src1,
  input wire word_t src2,
  input wire alu_op_t alu_op,
  output word_t result,
  output logic true_flag
);

  always_comb begin
    unique case (alu_op)
      ALU_ADD: result = src1 + src2;
      ALU_SUB: result = src1 - src2;
      ALU_EQ:  result = src1 == src2;
      ALU_NE:  result = src1 != src2;
      ALU_LT:  result = src1 < src2;
      ALU_GE:  result = src1 >= src2;
    endcase
  end

  assign true_flag = (result == 1'b1);

endmodule

`default_nettype wire
