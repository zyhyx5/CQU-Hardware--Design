`timescale 1ns / 1ps
`include "my_mips.svh"
`include "define.svh"
module mips (
    input wire clk,
    input wire rst,
    

    input  inst_sram_data_t  inst_sram_data,
    output fetch_data_out_t  fetch_data_out,
    input  data_sram_data_t  data_sram_data,
    output memory_data_out_t memory_data_out,
    output wb_data_out_t     wb_data_out

);
    //-----------------------信号定义---------------------
    //控制信号
    control_sign_t decode_sign, execute_sign, wb_sign;

    //数据实例
    control_data_t control_data;
    decode_data_t  decode_data;
    execute_data_t execute_data;

    //------------------------控制器------------------------
    //控制器，实现译码
    main_decode main_decode (
        .rst        (rst),
        .decode_data(decode_data),
        .execute_sign(execute_sign),
        .cdt        (control_data),
        .clt        (decode_sign)
    );

    //------------------------配置硬件中断信息---------------
    // assign decode_sign.ext_int = decode_data.ext_int;



    //-----------------------------数据通路--------------------
    datapath datapath_dut (
        .clk(clk),
        .rst(rst),


        .inst_sram_data (inst_sram_data),
        .fetch_data_out (fetch_data_out),
        .data_sram_data (data_sram_data),
        .memory_data_out(memory_data_out),
        .wb_data_out    (wb_data_out),

        .decode_data (decode_data),
        .control_data(control_data),
        .decode_sign (decode_sign),
        .execute_sign(execute_sign)

    );
    //-----------------------------
endmodule
