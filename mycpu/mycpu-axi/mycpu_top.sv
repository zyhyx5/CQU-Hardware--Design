`include "my_mips.svh"
`include "define.svh"
`timescale 1ns / 1ps
module mycpu_top (
    //时钟/复位与中断
    input logic clk,resetn,

    //6位硬件中断
    input logic [5:0] ext_int,

    //取值端访存接口
    output logic  inst_sram_en,
    output wen_t  inst_sram_wen,
    output word_t inst_sram_addr,
    output word_t inst_sram_wdata,
    input  word_t inst_sram_rdata,


    //数据端访存接口
    output logic  data_sram_en,
    output wen_t  data_sram_wen,
    output word_t data_sram_addr,
    output word_t data_sram_wdata,
    input  word_t data_sram_rdata,

    //debug信号，供验证平台使用
    output word_t     debug_wb_pc,
    output wen_t      debug_wb_rf_wen,   //regfile写使能，扩展成4位
    output reg_addr_t debug_wb_rf_wnum,  //写回目的寄存器号
    output word_t     debug_wb_rf_wdata  //写回寄存器的数据 


);

    //从sram得到的数据
    inst_sram_data_t  inst_sram_data;
    data_sram_data_t  data_sram_data;
    fetch_data_out_t  fetch_data_out;
    memory_data_out_t memory_data_out;
    wb_data_out_t     wb_data_out;




    //-------------------配置sram接口---------------
    //配置inst_sram
    always_comb begin
        inst_sram_en         = 1;
        inst_sram_wen        = 0;
        inst_sram_addr       = fetch_data_out.pc;
        inst_sram_wdata      = 0;
        inst_sram_data.instr = inst_sram_rdata;

        inst_sram_data.ext_int = ext_int;
    end

    //配置data_sram
    always_comb begin
        data_sram_en            = 1;
        data_sram_wen           = memory_data_out.wen;
        data_sram_addr          = memory_data_out.mem_addr;
        data_sram_wdata         = memory_data_out.writedata;
        data_sram_data.readdata = data_sram_rdata;
    end

    //配置debug信号
    always_comb begin
        debug_wb_pc       = wb_data_out.pc;
        debug_wb_rf_wen   = wb_data_out.regwrite;
        debug_wb_rf_wnum  = wb_data_out.writereg;
        debug_wb_rf_wdata = wb_data_out.result;  //写回寄存器的数据 
    end

    //mips模块
    mips mips_dut (
        .clk(clk),
        .rst(resetn),
                                           
        .inst_sram_data (inst_sram_data),
        .fetch_data_out (fetch_data_out),
        .data_sram_data (data_sram_data),
        .memory_data_out(memory_data_out),
        .wb_data_out  (wb_data_out)

    );


endmodule
