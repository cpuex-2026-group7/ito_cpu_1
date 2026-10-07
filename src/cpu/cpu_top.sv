`timescale 1ns / 1ps
`default_nettype none

module cpu_top
  import types::*;
  import isa::*;
(
  input wire logic clk,
  input wire logic rst,
  input wire logic en,
  input wire logic uart_rx,
  output logic uart_tx,
  output logic [31:0] pc_for_dbg,
  input wire logic [5:0] reg_num_for_dbg,
  output logic [31:0] reg_data_for_dbg,
  output logic cpu_halted
);

  addr_t pc = 32'b0;
  addr_t pc_plus_1;
  assign pc_plus_1 = pc + 32'd1;

  instr_t instr;
  i_mem imem (
    .addr (pc),
    .instr(instr)
  );

  logic
    alu_true_flag,
    pc_flag,
    mem_write_flag,
    alu_or_fpu_flag,
    alu_src_flag,
    normal_reg_write_flag,
    f_reg_write_flag,
    cpu_halted;
  logic [1:0] result_flag, wdata_flag, imm_length_flag;
  alu_op_t alu_op;
  fpu_op_t fpu_op;
  decoder u_decoder (
    .instr(instr),
    .alu_true_flag(alu_true_flag),
    .pc_flag(pc_flag),
    .result_flag(result_flag),
    .mem_write_flag(mem_write_flag),
    .alu_or_fpu_flag(alu_or_fpu_flag),
    .alu_op(alu_op),
    .alu_src_flag(alu_src_flag),
    .fpu_op(fpu_op),
    .wdata_flag(wdata_flag),
    .imm_length_flag(imm_length_flag),
    .normal_reg_write_flag(normal_reg_write_flag),
    .f_reg_write_flag(f_reg_write_flag),
    .cpu_halted(cpu_halted)
  );

  word_t extended_imm;
  imm_extend u_imm_extend (
    .imm15(instr[14:0]),
    .imm20(instr[19:0]),
    .imm_length_flag(imm_length_flag),
    .extended_imm(extended_imm)
  );

  reg_addr_t addr1, addr2, addr3;
  assign addr1 = instr[24:20];
  assign addr2 = instr[19:15];
  assign addr3 = instr[14:10];
  word_t n_rdata1, n_rdata2, f_rdata1, f_rdata2, write_back_data;
  reg_file normal_reg_file (
    .clk(clk),
    .rst(rst),
    .write_en(normal_reg_write_flag),
    .addr1(addr1),
    .addr2(addr2),
    .addr3(addr3),
    .wdata(write_back_data),
    .rdata1(n_rdata1),
    .rdata2(n_rdata2)
  );
  reg_file f_reg_file (
    .clk(clk),
    .rst(rst),
    .write_en(f_reg_write_flag),
    .addr1(addr1),
    .addr2(addr2),
    .addr3(addr3),
    .wdata(write_back_data),
    .rdata1(f_rdata1),
    .rdata2(f_rdata2)
  );

  addr_t jumped_pc;
  assign jumped_pc = pc_plus_1 + extended_imm;

  word_t alu_src1, alu_src2, fpu_src1, fpu_src2, alu_result, fpu_result;
  alu_intr_t alu_intr;
  fpu_intr_t fpu_intr;
  assign alu_src1 = n_rdata1;
  assign alu_src2 = alu_src_flag ? extended_imm : n_rdata2;
  assign fpu_src1 = f_rdata1;
  assign fpu_src2 = f_rdata2;
  alu u_alu (
    .src1(alu_src1),
    .src2(alu_src2),
    .alu_op(alu_op),
    .result(alu_result),
    .true_flag(alu_true_flag)
  );
  fpu_top u_fpu (
    .src1  (fpu_src1),
    .src2  (fpu_src2),
    .fpu_op(fpu_op),
    .result(fpu_result),
  );

  word_t hard_coded_data;
  hard_code u_hard_code (
    .addr(extended_imm),
    .data(hard_coded_data)
  );

  word_t mem_wdata = alu_src_flag ? f_rdata1 : n_rdata1;
  word_t mem_rdata;
  d_mem u_d_mem (
    .clk(clk),
    .rst(rst),
    .write_en(mem_write_flag),
    .addr(alu_result),
    .wdata(mem_wdata),
    .rdata(mem_rdata)
  );

  assign write_back_data = result_flag == 3'b000 ? alu_result :
                           result_flag == 3'b001 ? fpu_result :
                           result_flag == 3'b010 ? mem_rdata :
                           result_flag == 3'b011 ? extended_imm :
                           result_flag == 3'b100 ? hard_coded_data
                           : pc_plus_1;

  always_ff @(posedge clk) begin
    if (rst) begin
      pc <= 32'b0;
    end else if (en) begin
      pc <= pc_flag ? jumped_pc : pc_plus_1;
    end
  end

  always_comb begin
    if (reg_num_for_dbg < 6'd32) begin
      reg_data_for_dbg = {26'd0, reg_num_for_dbg};
    end else begin
      reg_data_for_dbg = 32'b0;
    end
  end

  assign uart_tx = 1'b0;
  assign pc_for_dbg = pc;
endmodule

`default_nettype wire
