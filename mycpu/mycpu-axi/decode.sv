`include "my_mips.svh"
`include "define.svh"
module decode (
    input                clk,
    input                rst,
    input control_sign_t decode_sign,
    input control_sign_t execute_sign,
    input control_sign_t memory_sign,
    input control_sign_t wb_sign,

    input control_data_t control_data,
    input fetch_data_t   decode_data_in,
    input execute_data_t execute_data,
    input memory_data_t  memory_data,
    input wb_data_t      wb_data,


    output decode_data_t decode_data,
    output logic         stall_reqD_load
);

    //对decode_data进行赋值
    always_comb begin
        decode_data.writereg = control_data.writereg;
        decode_data.imm      = control_data.imm;
        decode_data.instr    = decode_data_in.instr;
        decode_data.pc       = decode_data_in.pc;
        decode_data.rs_addr  = decode_data_in.instr[25:21];
        decode_data.rt_addr  = decode_data_in.instr[20:16];
        decode_data.rd_addr  = decode_data_in.instr[15:11];
        decode_data.ext_int  = decode_data_in.ext_int;  //配置硬件中断信息
    end

    //D阶段：寄存器
    regfile regfile_dut (
        .clk(clk),
        .rst(rst),


        .we   (wb_sign.regwrite),
        .waddr(wb_data.writereg),
        .wdata(wb_data.result),

        .re1   (decode_sign.reg1_read),
        .raddr1(decode_data.rs_addr),
        .rdata1(decode_data.RD1_data),

        .re2   (decode_sign.reg2_read),
        .raddr2(decode_data.rt_addr),
        .rdata2(decode_data.RD2_data),


        .stall_reqD_load(stall_reqD_load),

        .control_data(control_data),
        .E_data      (execute_data),
        .M_data      (memory_data),

        .E_sign(execute_sign),
        .M_sign(memory_sign)

    );


endmodule
