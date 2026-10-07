`timescale 1ns / 1ps
`default_nettype none

module fpu_top
  import types::*;
  import isa::*;
(
  input wire word_t src1,
  input wire word_t src2,
  input wire fpu_op_t fpu_op,
  output word_t result
);

  always_comb begin
    unique case (fpu_op)
      FPU_FCVT_S_W: result = 32'd0;
      FPU_FCVT_W_S: result = 32'd1;
      FPU_FSQRT: result = 32'd2;
      FPU_FMV: result = 32'd3;
      FPU_FNEG: result = 32'd4;
      FPU_FABS: result = 32'd5;
      FPU_FEQ: result = 32'd6;
      FPU_FLT: result = 32'd7;
      FPU_FADD: result = 32'd8;
      FPU_FSUB: result = 32'd9;
      FPU_FMUL: result = 32'd10;
      FPU_FDIV: result = 32'd11;
    endcase
  end

endmodule

`default_nettype wire
