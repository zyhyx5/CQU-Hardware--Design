`include "../my_mips.svh"
`include "../define.svh"

module new_cp0 (
    input logic clk,
    input logic rst,


    // CP0 req
    input  cp0_rreq_t cp0_rreq,
    input  cp0_wreq_t cp0_wreq,
    //cp0为MFC0指令读出的数据
    output word_t     cp0_rdata,

    //与mem阶段的异常判断模块交互
    input exception_sign_t exception_sign,
    input exception_data_t exception_data,

    //exception
    output cp0_cause_t  cp0_cause,
    output cp0_status_t cp0_status,
    output word_t       cp0_epc,
    output logic        timer_interrupt
);

    cp0_regs_t cp0, cp0_new;
    word_t wd;
    always_ff @(posedge clk) begin
        if (!rst) begin
            cp0 <= `CP0_INIT;
        end else begin
            cp0 <= cp0_new;
        end
    end

    logic count_switch = 0;  //count寄存器计数

    always_ff @(posedge clk) begin
        if (!rst) begin
            count_switch <= 1'b0;
        end else begin
            count_switch <= ~count_switch;
        end
    end

    // read
    always_comb begin
        case (cp0_rreq.raddr)
            5'd8: cp0_rdata = cp0.badvaddr;
            5'd9: cp0_rdata = cp0.count;
            5'd11: cp0_rdata = cp0.compare;
            5'd12: cp0_rdata = cp0.status;
            5'd13: cp0_rdata = cp0.cause;
            5'd14: cp0_rdata = cp0.epc;
            5'd16: cp0_rdata = cp0.config_;
            default: cp0_rdata = '0;
        endcase
    end


    // update cp0 registers
    always_comb begin
        
        cp0_new = cp0;

        //获得timer_interrupt信号
        cp0_new.count = cp0_new.count + count_switch;  //count寄存器
        if (!rst) begin
            timer_interrupt = 1'b0;
        end else if (cp0_new.count == cp0_new.compare) begin
            timer_interrupt = 1'b1;
        end else if ((cp0_wreq.we & cp0_wreq.waddr == `COMPARE) | (cp0_wreq.we & cp0_wreq.waddr ==`COMPARE)) begin
            timer_interrupt = 1'b0;
        end

        // write
        if (cp0_wreq.we) begin
            case (cp0_wreq.waddr)
                5'd9: cp0_new.count = cp0_wreq.wdata;
                5'd11: cp0_new.compare = cp0_wreq.wdata;
                5'd12: begin
                    cp0_new.status.IM  = cp0_wreq.wdata[15:8];
                    cp0_new.status.EXL = cp0_wreq.wdata[1];
                    cp0_new.status.IE  = cp0_wreq.wdata[0];
                end
                5'd13: cp0_new.cause.IP[1:0] = cp0_wreq.wdata[9:8];  //对于cause寄存器一般只写两位的软件中断
                5'd14: cp0_new.epc = cp0_wreq.wdata;
                default: ;
            endcase
        end


        // exception
        if (exception_sign.valid) begin
            if (~cp0.status.EXL) begin
                if (exception_sign.delayslot) begin
                    cp0_new.cause.BD = 1'b1;
                    cp0_new.epc = exception_sign.pc - 32'd4;
                end else begin
                    cp0_new.cause.BD = 1'b0;
                    cp0_new.epc = exception_sign.pc;
                end
            end

            cp0_new.cause.exccode = exception_data.code;


            cp0_new.status.EXL = 1'b1;
            if (exception_data.code == CODE_ADEL || exception_data.code == CODE_ADES) begin
                cp0_new.badvaddr = exception_sign.badvaddr;
            end
        end

        if (exception_sign.is_eret) begin
            if (cp0.status.ERL) begin
                cp0_new.status.ERL = 1'b0;
            end else begin
                cp0_new.status.EXL = 1'b0;
            end
            // llbit = 1'b0;
        end
    end


    assign cp0_status = cp0.status;
    assign cp0_cause = cp0.cause;
    assign cp0_epc = cp0.epc;

endmodule
