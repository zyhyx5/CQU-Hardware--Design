`include "../my_mips.svh"
`include "../define.svh"


module execept_check (

    input logic rst,

    //数据通路  交互
    input control_sign_t memory_sign,
    input memory_data_t  memory_data,

    //cp0  交互
    input cp0_cause_t  cp0_cause,
    input cp0_status_t cp0_status,
    input logic        timer_interrupt,

    //wb阶段写向cp0的数据
    input control_sign_t wb_sign,

    //输出信息
    output exception_data_t exception_data,  //异常数据
    output exception_sign_t exception_sign   //异常信号

);

    inst_name_t        name;
    word_t             mem_addr;
    logic        [5:0] ext_int;

    cp0_cause_t        cause_reg;
    cp0_status_t       status_reg;

    cp0_wreq_t         cp0_wreq;


    assign name     = memory_sign.instr_name;
    assign mem_addr = memory_sign.mem_addr;
    assign ext_int  = memory_data.ext_int;
    assign cp0_wreq = wb_sign.cp0_wreq;
    //当wb阶段时MTC0时，进行数据前推
    always_comb begin

        if (!rst) begin
            cause_reg  = 0;
            status_reg = 0;

        end else begin
            status_reg = cp0_status;
            cause_reg  = cp0_cause;
            if (wb_sign.instr_name == MTC0) begin
                if (cp0_wreq.we && cp0_wreq.waddr == `CAUSE) begin
                    cause_reg.IP[1:0] = cp0_wreq.wdata[9:8];
                end else begin
                    cause_reg = cp0_cause;
                end
                if (cp0_wreq.we && cp0_wreq.waddr == `STATUS) begin
                    status_reg = cp0_wreq.wdata;
                end else begin
                    status_reg = cp0_status;
                end

            end else begin
            end
        end


    end
    always_comb begin
        if (!rst) begin
            exception_sign = 0;
        end else begin
            exception_sign = 0;
            exception_sign.pc = memory_data.pc;
            exception_sign.ext_int = memory_data.ext_int;

            //四种异常
            exception_sign.ri = (memory_sign.valid == 0 && memory_data.instr != 0);  //指令是否有效，用与判断ri（保留指令异常）
            exception_sign.delayslot = memory_sign.now_delayslot;  //延迟槽，用于确定返回地址寄存器epc的值，同时cause.bd置位1
            exception_sign.ov = memory_sign.overflow;  //溢出异常
            exception_sign.exception_instr = (memory_data.pc[1:0] != '0);  //取指地址不对齐，发生ADEL异常，同时用于作为判断BadVAddr寄存器值的信号


            //三条异常指令的判断
            exception_sign.is_eret = (name == ERET);
            exception_sign.is_break = (name == BREAK);
            exception_sign.is_syscall = (name == SYSCALL);

            //地址错例外
            exception_sign.adel = ((name == LW) && (mem_addr[1:0] != '0)) ||
            ((name == LH || name == LHU) && (mem_addr[0] != '0));
            exception_sign.ades = ((name == SW) && (mem_addr[1:0] != '0)) ||
            ((name == SH) && (mem_addr[0] != '0));

            //badvaddr寄存器  这里写的不一定正确
            exception_sign.badvaddr = (exception_sign.exception_instr) ? memory_data.pc : mem_addr;
            exception_sign.epc = (exception_sign.delayslot) ? memory_data.pc - 4 : memory_data.pc;

            //中断信息
            exception_sign.interrupt_info = ({ext_int, 2'b00} | cause_reg.IP | {timer_interrupt, 7'b0}) 
            & {status_reg.IM};
            exception_sign.interrupt_valid = (exception_sign.interrupt_info != 0) 
            & (status_reg.IE)   //instruction_enable 全局中断使能位,high active
            & (~status_reg.EXL) //exception_level,当例外发生时，该位将被置位1;0：正常级，1：异常级
                                //当exl为1时，处理器处于核心态，不再处理例外，只有为0时，才处理例外
            & (~status_reg.ERL); //error_level,表示是否处理错误级，当处理器收到坏的数据时置1.
        end

        if (!rst) begin
            exception_data = 0;
            exception_data.ascii  = "CODE_NOP";
            exception_data.code  = CODE_NOP;
        end else begin
            if (exception_sign.interrupt_valid) begin
                exception_data.ascii  = "CODE_INT";
                exception_data.code  = CODE_INT;
                exception_data.valid = 1'b1;
            end else if (exception_sign.exception_instr) begin
                exception_data.ascii  = "CODE_ADEL";
                exception_data.code  = CODE_ADEL;
                exception_data.valid = 1'b1;
            end else if (exception_sign.ri) begin
                exception_data.ascii  = "CODE_RI";
                exception_data.code  = CODE_RI;
                exception_data.valid = 1'b1;
            end else if (exception_sign.ov) begin
                exception_data.ascii  = "CODE_OV";
                exception_data.code  = CODE_OV;
                exception_data.valid = 1'b1;
            end else if (exception_sign.is_syscall) begin
                exception_data.ascii  = "CODE_SYS";
                exception_data.code  = CODE_SYS;
                exception_data.valid = 1'b1;
            end else if (exception_sign.is_break) begin
                exception_data.ascii  = "CODE_BP";
                exception_data.code  = CODE_BP;
                exception_data.valid = 1'b1;
            end else if (exception_sign.adel) begin
                exception_data.code  = CODE_ADEL;
                exception_data.ascii  = "CODE_ADEL";
                exception_data.valid = 1'b1;
            end else if (exception_sign.ades) begin
                exception_data.ascii  = "CODE_ADES";
                exception_data.code  = CODE_ADES;
                exception_data.valid = 1'b1;
            end else begin
                exception_data.valid = 1'b0;
                exception_data.ascii  = "CODE_NOP";
                exception_data.code  = CODE_NOP;
            end

            exception_sign.valid = exception_data.valid; 
        end
    end


  
endmodule
