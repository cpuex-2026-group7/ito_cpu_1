`timescale 1ns / 1ps
`default_nettype none

// imm_length_flagが00-> imm15の符号拡張、01-> imm20の符号拡張、10-> imm20をfloatの上位20bitとして拡張(0埋め)
module imm_extend
  import types::*;
(
  input wire logic [14:0] imm15,
  input wire logic [19:0] imm20,
  input wire logic [1:0] imm_length_flag,
  output word_t extended_imm
);

  always_comb begin
    if (imm_length_flag == 2'b00) begin
      extended_imm = {{17{imm15[14]}}, imm15};
    end else if (imm_length_flag == 2'b01) begin
      extended_imm = {{12{imm20[19]}}, imm20};
    end else if (imm_length_flag == 2'b10) begin
      extended_imm = {imm20, 12'b0};
    end
  end

endmodule

`default_nettype wire
