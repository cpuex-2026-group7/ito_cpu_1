package isa;
  import types::*;
  typedef logic [4:0] reg_addr_t;

  typedef enum logic [6:0] {
    OP_HALT     = 7'b0000000,
    OP_ADD      = 7'b0011000,
    OP_SUB      = 7'b0011001,
    OP_JAL      = 7'b0101000,
    OP_LW       = 7'b0110000,
    OP_SW       = 7'b0110001,
    OP_BEQ      = 7'b0110010,
    OP_BNE      = 7'b0110011,
    OP_BLT      = 7'b0110100,
    OP_BGE      = 7'b0110101,
    OP_ADDI     = 7'b0110110,
    OP_JALR     = 7'b0110111,
    OP_FCVT_S_W = 7'b1010000,
    OP_FCVT_W_S = 7'b1010001,
    OP_FSQRT    = 7'b1010010,
    OP_FMV      = 7'b1010011,
    OP_FNEG     = 7'b1010100,
    OP_FABS     = 7'b1010101,
    OP_FEQ      = 7'b1011000,
    OP_FLT      = 7'b1011001,
    OP_FADD     = 7'b1011010,
    OP_FSUB     = 7'b1011011,
    OP_FMUL     = 7'b1011100,
    OP_FDIV     = 7'b1011101,
    OP_FLI      = 7'b1101000,
    OP_FLIM     = 7'b1101001,
    OP_FLW      = 7'b1110000,
    OP_FSW      = 7'b1110001
  } opcode_t;

  typedef struct packed {
    opcode_t    op;     // [31:25]
    reg_addr_t   area1;  // [24:20]
    reg_addr_t   area2;  // [19:15]
    reg_addr_t   area3;  // [14:10]
    logic [9:0] area4;  // [9:0]
  } instr_t;

  typedef enum logic [2:0] {
    ALU_ADD,
    ALU_SUB,
    ALU_EQ,
    ALU_NE,
    ALU_LT,
    ALU_GE
  } alu_op_t;

  typedef enum logic [3:0] {
    FPU_FCVT_S_W,
    FPU_FCVT_W_S,
    FPU_FSQRT,
    FPU_FMV,
    FPU_FNEG,
    FPU_FABS,
    FPU_FEQ,
    FPU_FLT,
    FPU_FADD,
    FPU_FSUB,
    FPU_FMUL,
    FPU_FDIV
  } fpu_op_t;

endpackage
