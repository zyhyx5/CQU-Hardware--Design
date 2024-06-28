`include "my_mips.svh"
`include "my_interface.svh"
`include "define.svh"

module datapath (
    input  wire              clk,
    input  wire              rst,
    input  inst_sram_data_t  inst_sram_data,
    output fetch_data_out_t  fetch_data_out,
    input  data_sram_data_t  data_sram_data,
    output memory_data_out_t memory_data_out,
    output wb_data_out_t     wb_data_out,

    output control_sign_t execute_sign,
    output decode_data_t  decode_data,
    input  control_data_t control_data,
    input  control_sign_t decode_sign
);
    //控制信号
    control_sign_t memory_sign, wb_sign;

    hazard_sign_t hazard_sign;

    //数据实例
    fetch_data_t fetch_data, decode_data_in;
    decode_data_t execute_data_in;
    execute_data_t execute_data, memory_data_in;
    memory_data_t memory_data, wb_data_in;
    wb_data_t        wb_data;
    hilo_data_t      hilo_data;

    //暂停信号
    stall_req_sign_t stall_req;
    stall_sign_t     stall;
    flush_sign_t flush, flush_req;

    //cp0相关
    logic            [7:0] interrupt_flag;
    word_t                 cp0_rdata;
    logic                  timer_interrupt;
    cp0_cause_t            cp0_cause;
    cp0_status_t           cp0_status;

    //异常信号
    exception_sign_t       exception_sign;
    exception_data_t       exception_data;
    word_t                 pc_exception;
    word_t                 cp0_epc;
    logic                  overflow;

    //---------------------------------------F阶段--------------------------------
    ////---------------------------------------F阶段--------------------------------
    fetch fetch (
        .clk(clk),
        .rst(rst),


        .inst_sram_data(inst_sram_data),
        .decode_data   (decode_data),
        .decode_sign   (decode_sign),
        .memory_sign   (memory_sign),

        .fetch_data    (fetch_data),
        .fetch_data_out(fetch_data_out),

        .stall       (stall),
        .pc_exception(pc_exception)
    );
    //---------------------------------------D阶段--------------------------------
    ////---------------------------------------D阶段--------------------------------




    f_d_reg f_d_reg_dut (
        .clk     (clk),
        .rst     (rst),
        .stallD  (stall.stallD),
        .clear   (flush.flushD),
        .data_in (fetch_data),
        .data_out(decode_data_in)
    );

    decode decode_dut (
        .clk(clk),
        .rst(rst),

        .decode_sign (decode_sign),
        .execute_sign(execute_sign),
        .memory_sign (memory_sign),
        .wb_sign     (wb_sign),


        .control_data  (control_data),
        .decode_data_in(decode_data_in),
        .execute_data  (execute_data),
        .memory_data   (memory_data),
        .wb_data       (wb_data),

        .decode_data    (decode_data),
        .stall_reqD_load(stall_req.stall_reqD_load)
    );

    //---------------------------------------E阶段--------------------------------
    ////---------------------------------------E阶段--------------------------------


    d_e_reg d_e_reg_dut (
        .clk     (clk),
        .rst     (rst),
        .stallE  (stall.stallE),
        .clear   (flush.flushE),
        .data_in (decode_data),
        .sign_in (decode_sign),
        .sign_out(execute_sign),
        .data_out(execute_data_in)
    );

    execute execute_inst (
        .clk(clk),
        .rst(rst),

        //信号
        .execute_sign(execute_sign),
        .memory_sign (memory_sign),
        .wb_sign     (wb_sign),

        //输入数据
        .execute_data_in(execute_data_in),
        .memory_data    (memory_data),
        .wb_data        (wb_data),
        .hilo_data      (hilo_data),
        .cp0_rdata      (cp0_rdata),

        //输入异常数据
        .exception_sign(exception_sign),

        //输出数据
        .overflow      (overflow),
        .execute_data  (execute_data),
        .stall_reqE    (stall_req.stall_reqE),
        .stall_reqE_div(stall_req.stall_reqE_div),
        .exe_sram      (memory_data_out)

    );




    //-------------------------------------M阶段--------------------------------
    //-------------------------------------M阶段--------------------------------
    e_m_reg e_m_reg_dut (
        .clk     (clk),
        .rst     (rst),
        .stallM  (stall.stallM),
        .overflow(overflow),
        .clear   (flush.flushM),
        .sign_in (execute_sign),
        .sign_out(memory_sign),
        .data_in (execute_data),
        .data_out(memory_data_in)
    );

    memory memory_dut (
        .rst           (rst),
        //与data_sram交互的数据
        .data_sram_data(data_sram_data),

        //与exe阶段交互的数据
        .memory_data_in(memory_data_in),
        .memory_sign   (memory_sign),

        //与wb阶段交互的数据
        .wb_sign(wb_sign),


        //输出的异常数据
        .exception_data(exception_data),
        .exception_sign(exception_sign),

        //cp0阶段输入数据信号
        .cp0_cause      (cp0_cause),
        .cp0_status     (cp0_status),
        .timer_interrupt(timer_interrupt),

        //mem阶段产生的数据
        .memory_data(memory_data)

    );

    //-------------------------------------W阶段--------------------------------
    //-------------------------------------W阶段--------------------------------

    m_w_reg m_w_reg_dut (
        .clk     (clk),
        .rst     (rst),
        .stallW  (stall.stallW),
        .clear   (flush.flushW),
        .sign_in (memory_sign),
        .sign_out(wb_sign),
        .data_in (memory_data),
        .data_out(wb_data_in)
    );



    writeback writeback_inst (
        .clk(clk),
        .rst(rst),

        .wb_data_in (wb_data_in),
        .wb_sign    (wb_sign),
        .wb_data    (wb_data),
        .wb_data_out(wb_data_out),

        //hilo交互
        .hilo_data(hilo_data)
    );


    new_cp0 cp0_inst (
        .clk     (clk),
        .rst     (rst),
        //与wb阶段交互
        .cp0_rreq(execute_sign.cp0_rreq),
        .cp0_wreq(wb_data.cp0_wreq),

        //与exception数据交互
        .exception_sign(exception_sign),
        .exception_data(exception_data),

        //输出数据
        .cp0_rdata      (cp0_rdata),
        .cp0_cause      (cp0_cause),
        .cp0_status     (cp0_status),
        .cp0_epc        (cp0_epc),
        .timer_interrupt(timer_interrupt)
    );

    //-------------------------------------ctrl--------------------------------
    //-------------------------------------ctrl--------------------------------

    ctrl ctrl (
        .rst           (rst),
        //输出请求暂停清空信号
        .stall_req     (stall_req),
        .flush_req     (flush_req),
        //输入信号
        .memory_sign   (memory_sign),
        .wb_sign       (wb_sign),
        .exception_sign(exception_sign),
        .exception_data(exception_data),
        .cp0_epc       (cp0_epc),
        // 输出数据
        .s             (stall),
        .f             (flush),
        .pc_exception  (pc_exception)
    );

endmodule
