`timescale 1ns / 1ps
`default_nettype none

module hard_code
  import types::*;
(
  input wire word_t idx,
  input wire word_t data
);

  assign data = idx > 32'd63 ? 32'd0 : idx;

endmodule

`default_nettype wire
