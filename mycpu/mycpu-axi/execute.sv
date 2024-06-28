`include "my_mips.svh"
`include "define.svh"


module execute (
    input logic clk,
    input logic rst,

    input control_sign_t execute_sign,
    input control_sign_t memory_sign,
    input control_sign_t wb_sign,

    input decode_data_t execute_data_in,
    input memory_data_t memory_data,
    input wb_data_t     wb_data,

    input hilo_data_t hilo_data,

    input word_t cp0_rdata,

    //输入异常信息
    input exception_sign_t exception_sign,


    output                   overflow,        //溢出标志
    output execute_data_t    execute_data,
    output logic             stall_reqE,
    output logic             stall_reqE_div,
    output memory_data_out_t exe_sram

);
    double_word_t HILO;
    //处理cp0中的值转移
    cp0_rreq_t    cp0_rreq_E;
    cp0_wreq_t cp0_wreq_E, cp0_wreq_M, cp0_wreq_W;
    double_word_t cc;

    logic end_div;
    
    //除法指令 
    double_word_t temp_div;
    logic         ready_div;

    always_comb begin
        cp0_rreq_E = execute_sign.cp0_rreq;

        cp0_wreq_E = execute_sign.cp0_wreq;
        cp0_wreq_M = memory_sign.cp0_wreq;
        cp0_wreq_W = wb_sign.cp0_wreq;
    end


    always_comb begin
        execute_data.instr    = execute_data_in.instr;
        execute_data.writereg = execute_data_in.writereg;
        execute_data.imm      = execute_data_in.imm;
        execute_data.pc       = execute_data_in.pc;
        execute_data.rs_addr  = execute_data_in.rs_addr;
        execute_data.rt_addr  = execute_data_in.rt_addr;
        execute_data.rd_addr  = execute_data_in.rd_addr;
        execute_data.RD1_data = execute_data_in.RD1_data;
        execute_data.RD2_data = execute_data_in.RD2_data;
        execute_data.ext_int  = execute_data_in.ext_int;

        //处理跳转指令
        if (execute_sign.instr_class == JAL_) begin
            execute_data.srca = execute_sign.link_addr;
            //处理MFC0指令
        end else if (execute_sign.instr_name == MFC0 && cp0_wreq_M.we && cp0_wreq_M.waddr == cp0_rreq_E.raddr) begin
            execute_data.srca = cp0_wreq_M.wdata;
        end else if (execute_sign.instr_name == MFC0 && cp0_wreq_W.we && cp0_wreq_W.waddr == cp0_rreq_E.raddr) begin
            execute_data.srca = cp0_wreq_W.wdata;
        end else if (execute_sign.instr_name == MFC0) begin
            execute_data.srca = cp0_rdata;

            //处理MTC0指令    
        end else if (execute_sign.instr_name == MTC0) begin
            execute_data.cp0_wreq = cp0_wreq_E;
        end else begin
            execute_data.srca     = execute_data_in.RD1_data;
            execute_data.cp0_wreq = 0;
        end

    end

    //移动指令数据转发
    always_comb begin
        //移动指令数据转发  可以解决MFHI 和MFLO指令

        //mem阶段关于hilo寄存器的数据转发
        if (execute_sign.hitoreg && memory_sign.hiwrite) begin
            execute_data.srcb = memory_data.hi;
            HILO              = {memory_data.hi, memory_data.lo};
        end else if (execute_sign.lotoreg && memory_sign.lowrite) begin
            execute_data.srcb = memory_data.lo;
            HILO              = {memory_data.hi, memory_data.lo};

            //wb阶段关于hilo寄存器的数据转发
        end else if (execute_sign.hitoreg && wb_sign.hiwrite) begin
            execute_data.srcb = wb_data.hi;
            HILO              = {wb_data.hi, wb_data.lo};
        end else if (execute_sign.lotoreg && wb_sign.lowrite) begin
            execute_data.srcb = wb_data.lo;
            HILO              = {wb_data.hi, wb_data.lo};

            //没有出现数据前推的情况，直接从hilo寄存器获取数据
        end else if (execute_sign.hitoreg) begin
            execute_data.srcb = hilo_data.hi;
            HILO              = {hilo_data.hi, hilo_data.lo};
        end else if (execute_sign.lotoreg) begin
            execute_data.srcb = hilo_data.lo;
            HILO              = {hilo_data.hi, hilo_data.lo};

            //如果是其他非关于hilo或者cp0的指令
        end else begin
            execute_data.srcb = execute_data_in.RD2_data;
        end


        //可以解决MTHI 和MTLO指令
        if (execute_sign.hiwrite && !execute_sign.lowrite) begin
            execute_data.hi = execute_data_in.RD1_data;
        end else if (execute_sign.lowrite && !execute_sign.hiwrite) begin
            execute_data.lo = execute_data_in.RD1_data;
        end

        //可以解决MADD，MSUB等乘加，乘减指令的数据转发
        if ((execute_sign.lowrite && execute_sign.hiwrite) && (memory_sign.hiwrite || memory_sign.lowrite)) begin
            HILO = {memory_data.hi, memory_data.lo};
        end else if (execute_sign.lowrite && execute_sign.hiwrite && (wb_sign.hiwrite || wb_sign.lowrite)) begin
            HILO = {wb_data.hi, wb_data.lo};
        end else begin
            HILO = {hilo_data.hi, hilo_data.lo};
        end

        if (!rst) begin
            stall_reqE_div = 0;
        end else if (execute_sign.instr_name == DIV || execute_sign.instr_name == DIVU) begin
            if (ready_div == 0) begin
                stall_reqE_div = 1;
            end else if (ready_div == 1) begin
                {execute_data.hi, execute_data.lo} = temp_div;
                stall_reqE_div                     = 0;
            end

        end else begin
            stall_reqE_div = 0;
        end

        case (execute_sign.instr_name)
            MULT, MULTU, MADD, MADDU, MSUB, MSUBU: begin
                {execute_data.hi, execute_data.lo} = cc;
            end

        endcase

    end





    div div_inst (
        .clk      (clk),
        .rst      (rst),
        .opdata1  (execute_data.srca),
        .opdata2  (execute_data.srcb),
        .start_div(execute_sign.start_div),
        .annul_div(execute_sign.annul_div),
        .is_signed(execute_sign.is_signed),

        .result(temp_div),
        .ready (ready_div)
    );


    //输出load 和store指令的地址和信号
    pre_mem pre_mem_inst (
        .execute_data  (execute_data),
        .execute_sign  (execute_sign),
        .exception_sign(exception_sign),
        .exe_sram      (exe_sram)
    );







    //E阶段 alu运算?
    ALU ALU_inst (
        .clk         (clk),
        .rst         (rst),
        .a           (execute_data.srca),
        .b           (execute_data.srcb),
        .execute_sign(execute_sign),
        .memory_sign (memory_sign),
        .HILO        (HILO),

        .c         (execute_data.aluout),
        .cc        (cc),
        .overflow  (overflow),
        .stall_reqE(stall_reqE)
    );

endmodule
