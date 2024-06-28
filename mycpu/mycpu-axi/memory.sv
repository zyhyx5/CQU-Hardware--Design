`include "my_mips.svh"
`include "define.svh"
module memory (
    input rst,

    //与数据execute阶段交互
    input control_sign_t memory_sign,
    input execute_data_t memory_data_in,


    //与data_sram交互
    input data_sram_data_t data_sram_data,

    //与wb阶段交互
    input control_sign_t wb_sign,

    //cp0  交互
    input cp0_cause_t  cp0_cause,
    input cp0_status_t cp0_status,
    input logic        timer_interrupt,

    //输出memory阶段数据
    output memory_data_t memory_data,

    //输出的异常数据
    output exception_data_t exception_data,  //异常数据
    output exception_sign_t exception_sign   //异常信号


);

    word_t rdata, wdata, reg2_data, reg1_data, sram_data;
    assign rdata              = data_sram_data.readdata;
    assign memory_data.result = wdata;  //写给寄存器的数据
    assign reg1_data          = memory_data_in.RD1_data;
    assign reg2_data          = memory_data_in.RD2_data;

    always_comb begin
        if (memory_sign.instr_class == STORE_ || memory_sign.instr_class == LOAD_) begin

            case (memory_sign.instr_name)

                LB: begin
                    case (memory_sign.mem_addr[1:0])
                        2'b00: begin
                            wdata <= {{24{rdata[7]}}, rdata[7:0]};
                        end
                        2'b01: begin
                            wdata <= {{24{rdata[15]}}, rdata[15:8]};
                        end
                        2'b10: begin
                            wdata <= {{24{rdata[23]}}, rdata[23:16]};
                        end
                        2'b11: begin
                            wdata <= {{24{rdata[31]}}, rdata[31:24]};
                        end
                        default: begin
                            wdata <= 0;
                        end
                    endcase
                end

                LBU: begin
                    case (memory_sign.mem_addr[1:0])
                        2'b00: begin
                            wdata <= {{24{1'b0}}, rdata[7:0]};
                        end
                        2'b01: begin
                            wdata <= {{24{1'b0}}, rdata[15:8]};
                        end
                        2'b10: begin
                            wdata <= {{24{1'b0}}, rdata[23:16]};
                        end
                        2'b11: begin
                            wdata <= {{24{1'b0}}, rdata[31:24]};
                        end
                        default: begin
                            wdata <= 0;
                        end
                    endcase
                end
                LH: begin
                    case (memory_sign.mem_addr[1])
                        1'b0: begin
                            wdata = {{24{rdata[15]}}, rdata[15:0]};
                        end
                        1'b1: begin
                            wdata = {{24{rdata[31]}}, rdata[31:16]};
                        end
                        default: begin
                            wdata = 0;
                        end
                    endcase
                end
                LHU: begin
                    case (memory_sign.mem_addr[1])
                        1'b1: begin
                            wdata = {{24{1'b0}}, rdata[31:16]};
                        end
                        1'b0: begin
                            wdata = {{24{1'b0}}, rdata[15:0]};
                        end
                        default: begin
                            wdata = 0;
                        end
                    endcase
                end
                LW: begin
                    wdata = rdata;
                end
                LWL: begin
                    case (memory_sign.mem_addr[1:0])
                        2'b00: begin
                            wdata = rdata;
                        end
                        2'b01: begin
                            wdata = {rdata[23:0], reg2_data[7:0]};
                        end
                        2'b10: begin
                            wdata = {rdata[15:0], reg2_data[15:0]};
                        end
                        2'b11: begin
                            wdata = {rdata[7:0], reg2_data[23:0]};
                        end
                        default: begin
                            wdata = 0;
                        end
                    endcase
                end
                LWR: begin
                    case (memory_sign.mem_addr[1:0])
                        2'b00: begin
                            wdata = {reg2_data[31:8], rdata[31:24]};
                        end
                        2'b01: begin
                            wdata = {reg2_data[31:16], rdata[31:16]};
                        end
                        2'b10: begin
                            wdata = {reg2_data[31:24], rdata[31:8]};
                        end
                        2'b11: begin
                            wdata = rdata;
                        end
                        default: begin
                            wdata = 0;
                        end
                    endcase
                end
            endcase
        end else begin
            wdata = memory_data_in.aluout;
        end
    end


    always_comb begin
        memory_data.hi       = memory_data_in.hi;
        memory_data.lo       = memory_data_in.lo;
        memory_data.instr    = memory_data_in.instr;
        memory_data.aluout   = memory_data_in.aluout;
        memory_data.pc       = memory_data_in.pc;
        memory_data.writereg = memory_data_in.writereg;  //写寄存器地址
        memory_data.readdata = data_sram_data.readdata;
        memory_data.cp0_wreq = memory_data_in.cp0_wreq;
        memory_data.ext_int  = memory_data_in.ext_int;
    end



    execept_check execept_check (
        .rst(rst),

        //memory阶段输入数据信号
        .memory_sign(memory_sign),
        .memory_data(memory_data),

        //wb阶段写向cp0的数据
        .wb_sign(wb_sign),

        //cp0阶段输入数据信号
        .cp0_cause      (cp0_cause),
        .cp0_status     (cp0_status),
        .timer_interrupt(timer_interrupt),


        //异常数据，信号输出
        .exception_data(exception_data),
        .exception_sign(exception_sign)
    );
endmodule

