//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/10/06 20:04:02
// Design Name:
// Module Name: top
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`default_nettype none

module top(
  input  wire logic       CLK100MHZ,
  input  wire logic [0:0] SW,
  output      logic [0:0] LED
);
  logic clk_out1, clk_out2, locked;
  logic reset = 1'b0;

  clk_wiz_0 clk_gen (
    .clk_out1 (clk_out1),
    .clk_out2 (clk_out2),
    .reset    (reset),
    .locked   (locked),
    .clk_in1  (CLK100MHZ)
  );

  logic [1:0] sw_sync;
  always_ff @(posedge clk_out1) sw_sync <= {sw_sync[0], SW[0]};

  logic [23:0] count;
  always_ff @(posedge clk_out1) begin
    if (!locked || !sw_sync[1]) count <= '0;
    else                        count <= count + 24'd1;
  end

  assign LED[0] = count[23];
endmodule

`default_nettype wire
