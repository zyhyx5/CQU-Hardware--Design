`include "my_mips.svh"
`include "define.svh"
module writeback (
    input logic clk,
    input logic rst,

    //mem交互
    input  memory_data_t  wb_data_in,
    input  control_sign_t wb_sign,
    output wb_data_t      wb_data,
    output wb_data_out_t  wb_data_out,

    //hilo交互
    output hilo_data_t hilo_data


);


    always_comb begin
        wb_data.instr    = wb_data_in.instr;
        wb_data.pc       = wb_data_in.pc;
        wb_data.writereg = wb_data_in.writereg;
        wb_data.result   = wb_data_in.result;
        wb_data.hi       = wb_data_in.hi;
        wb_data.lo       = wb_data_in.lo;
        wb_data.cp0_wreq = wb_data_in.cp0_wreq;
    end

    always_comb begin
        wb_data_out.pc       = wb_data_in.pc;
        wb_data_out.regwrite = {4{wb_sign.regwrite}};
        wb_data_out.result   = wb_data.result;
        wb_data_out.writereg = wb_data_in.writereg;
    end

    hilo_reg hilo_reg (
        .clk      (clk),
        .rst      (rst),
        .wb_sign  (wb_sign),
        .wb_data  (wb_data),
        .hilo_data(hilo_data)
    );


endmodule
