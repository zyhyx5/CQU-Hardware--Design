`include "my_mips.svh"
`include "define.svh"
module fetch (
    input wire clk,
    input wire rst,

    input decode_data_t    decode_data,
    input inst_sram_data_t inst_sram_data,

    output fetch_data_t     fetch_data,
    output fetch_data_out_t fetch_data_out,

    input control_sign_t decode_sign,
    input control_sign_t memory_sign,

    input stall_sign_t stall,

    input word_t pc_exception


);

    pc_reg pc_gate (
        .clk         (clk),
        .rst         (rst),
        .memory_sign (memory_sign),
        .stall       (stall),
        .pc_exception(pc_exception),

        .pc_new(fetch_data_out.pc)
    );

    logic [32:0] pc_reg_value ;
    always_ff @(posedge clk) begin
        pc_reg_value = fetch_data_out.pc;
    end

    //fetch_data 的数据赋值
    always_comb begin
        fetch_data.pc = pc_reg_value;
        fetch_data.instr = inst_sram_data.instr;
        fetch_data.ext_int = inst_sram_data.ext_int;
    end

endmodule