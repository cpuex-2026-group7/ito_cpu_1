`timescale 1ns / 1ps
`default_nettype none

module decoder
  import isa::*;
(
  input wire instr_t instr,
  input wire logic alu_true_flag,
  output logic pc_flag,  // 1でbranchかjump
  output logic [2:0] result_flag,  // 000: ALU, 001: FPU, 010: MEM, 011: extended_imm, 100: ハードコード, 101: PC+1
  output logic mem_write_flag,
  output logic alu_or_fpu_flag,  // 0でALU、1でFPU
  output alu_op_t alu_op,
  output logic alu_src_flag,  // 0でrdata2、1でextemded_imm
  output fpu_op_t fpu_op,
  output logic [1:0] imm_length_flag, // 00: imm15の符号拡張、01: imm20の符号拡張、10: imm20をfloatの上位20bitとして拡張(0埋め)
  output logic normal_reg_write_flag,
  output logic f_reg_write_flag,
  output logic cpu_halted  // for debug
);

  logic i_f = instr[31];
  logic imm = instr[30];
  logic [1:0] op_num = instr[29:28];
  logic [2:0] id = instr[27:25];
  always_comb begin
    if (i_f) begin
      pc_flag = 1'b0;
      cpu_halted = 1'b0;
      alu_op = ALU_ADD;
      if (!imm) begin
        result_flag = 3'b001;
        mem_write_flag = 1'b1;
        alu_or_fpu_flag = 1'b1;
        alu_src_flag = 1'b0;
        if (op_num == 2'b00) begin
          fpu_op = id == 3'b000 ? FPU_CVT_S_W :
                    id == 3'b001 ? FPU_CVT_W_S :
                    id == 3'b010 ? FPU_SQRT:
                    id == 3'b011 ? FPU_MV:
                    id == 3'b100 ? FPU_NEG: FPU_ABS;
        end else begin
          fpu_op = id == 3'b000 ? FPU_EQ :
                    id == 3'b001 ? FPU_LT :
                    id == 3'b010 ? FPU_ADD:
                    id == 3'b011 ? FPU_SUB:
                    id == 3'b100 ? FPU_MUL: FPU_DIV;
        end
        imm_length_flag = 2'b00;

        if ({op_num, id} != 5'b10001) begin
          normal_reg_write_flag = 1'b0;
          f_reg_write_flag = 1'b1;
        end else begin
          normal_reg_write_flag = 1'b1;
          f_reg_write_flag = 1'b0;
        end

      end else begin
        alu_or_fpu_flag = 1'b0;
        alu_src_flag = 1'b1;
        normal_reg_write_flag = 1'b0;
        f_reg_write_flag = 1'b1;
        if (op_num == 2'b01) begin
          if (id == 3'b000) begin
            result_flag = 3'b011;
            imm_length_flag = 2'b10;
          end else begin
            result_flag = 3'b100;
            imm_length_flag = 2'b01;
          end
          mem_write_flag = 1'b0;
        end else begin
          result_flag = 3'b010;
          mem_write_flag = id == 3'b001 ? 1'b1 : 1'b0;
          imm_length_flag = 2'b00;
        end
      end

    end else begin
      alu_or_fpu_flag = 1'b0;
      fpu_op = FPU_FCVT_S_W;
      normal_reg_write_flag = 1'b1;
      f_reg_write_flag = 1'b0;
      if (!imm) begin
        pc_flag = 1'b0;
        result_flag = 3'b000;
        mem_write_flag = 1'b0;

        alu_op = id == 3'b000 ? ALU_ADD : ALU_SUB;
        alu_src_flag = 1'b0;
        imm_length_flag = 2'b00;

        cpu_halted = op_num == 2'b00 ? 1'b1 : 1'b0;

      end else begin
        if(op_num == 2'b01 || id == 3'b111 || (alu_true_flag && (id == 3'b010 || id == 3'b011 || id == 3'b100 || id == 3'b101))) begin
          pc_flag = 1'b1;
        end else begin
          pc_flag = 1'b0;
        end
        result_flag = id == 3'b111 ? 3'b101 : 3'b010;
        mem_write_flag = id == 3'b001 ? 1'b1 : 1'b0;
        alu_op = id == 3'b010 ? ALU_EQ : id == 3'b011 ? ALU_NE : id == 3'b100 ? ALU_LT : ALU_GE;
        alu_src_flag = 1'b1;
        imm_length_flag = op_num == 2'b01 ? 2'b01 : 2'b00;
        cpu_halted = 1'b0;
      end
    end

  end

endmodule

`default_nettype wire
