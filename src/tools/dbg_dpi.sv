`ifdef VERILATOR
package dbg_dpi;
  import "DPI-C" function void dpi_commit(
    input int pc,
    input int instr,
    input bit reg_we,
    input bit rd_is_f,
    input int rd,
    input int wdata,
    input bit mem_we,
    input int mem_addr,
    input int mem_data
  );
  import "DPI-C" function void dpi_dump_reg(
    input bit is_f,
    input int idx,
    input int data
  );
endpackage
`endif
