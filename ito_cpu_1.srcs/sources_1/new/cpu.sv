`timescale 1ns / 1ps
`default_nettype none

module cpu (
  input wire logic clk,
  input wire logic rst,
  input wire logic en,
  input wire logic uart_rx,
  output logic uart_tx,
  output logic [31:0] pc_for_dbg,
  input wire logic [5:0] reg_num_for_dbg,
  output logic [31:0] reg_data_for_dbg
);

  always_comb begin
    if (reg_num_for_dbg < 6'd32) begin
      reg_data_for_dbg = {27'd0, reg_num_for_dbg};
    end else begin
      reg_data_for_dbg = 32'b0;
    end
  end

  assign uart_tx = 1'b0;
  assign pc_for_dbg = 32'b0;
endmodule

`default_nettype wire
