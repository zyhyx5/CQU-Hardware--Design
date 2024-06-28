`include "my_mips.svh"
`include "define.svh"
module pre_mem (
    input execute_data_t   execute_data,
    input control_sign_t   execute_sign,
    input exception_sign_t exception_sign,


    output memory_data_out_t exe_sram

);

    inst_name_t name;
    word_t      mem_addr;
    assign name     = execute_sign.instr_name;
    assign mem_addr = execute_sign.mem_addr;
    logic adel, ades;

    always_comb begin
        //地址错例外
        adel = ((name == LW) && (mem_addr[1:0] != '0)) ||
        ((name == LH || name == LHU) && (mem_addr[0] != '0));
        ades = ((name == SW) && (mem_addr[1:0] != '0)) || ((name == SH) && (mem_addr[0] != '0));

    end


    word_t exe_sram_writedata, reg1_data, reg2_data;
    logic[3:0] wen;
    assign reg1_data = execute_data.RD1_data;
    assign reg2_data = execute_data.RD2_data;
    assign exe_sram.writedata = exe_sram_writedata;

    /*
    1. 如果mem阶段的指令发生异常，那么exe阶段的sw指令不能向data_sram发送写请求。
    2. 如果exe阶段的sw指令发生ades异常，那么必须在exe阶段就检测出来，并判断是否向data_sram发送请求。
    3. 如果mem阶段的指令是eret，那么exe阶段的sw指令不能向data_sram发送写请求。
    并且不能对exception_sign.ades赋值，只能用中间变量，如果对exception_sign.ades赋值，流水线就将乱套
    */
    assign exe_sram.wen = ((wen) 
    & {4{~exception_sign.valid}} 
    & {4{~ades}}
    & {4{~(execute_sign.instr_name == SYSCALL)}}
    & {4{~(exception_sign.is_eret)}});




    assign exe_sram.mem_addr = (execute_sign.mem_addr < 32'h80000000) ? execute_sign.mem_addr :
                        (execute_sign.mem_addr < 32'hA0000000) ? (execute_sign.mem_addr - 32'h80000000) :
                        (execute_sign.mem_addr < 32'hC0000000) ? (execute_sign.mem_addr - 32'hA0000000) :
                        (execute_sign.mem_addr < 32'hE0000000) ? (execute_sign.mem_addr) :
                        (execute_sign.mem_addr <= 32'hFFFFFFFF) ? (execute_sign.mem_addr) : 
                        32'h00000000;


    logic[8:0] x = 0;
    always_comb begin
        
        if (execute_sign.instr_class == STORE_ || execute_sign.instr_class == LOAD_) begin
            case (execute_sign.instr_name)
                SB: begin
                    exe_sram_writedata = {4{reg2_data[7:0]}};
                    case (execute_sign.mem_addr[1:0])
                        2'b00: begin
                            wen   = 4'b0001;
                            exe_sram_writedata = {24'b0, reg2_data[7:0]};
                        end
                        2'b01: begin
                            wen   = 4'b0010;
                            exe_sram_writedata = {16'b0, reg2_data[7:0], 8'b0};
                        end
                        2'b10: begin
                            wen   = 4'b0100;
                            exe_sram_writedata = {8'b0, reg2_data[7:0], 16'b0};
                        end
                        2'b11: begin
                            wen   = 4'b1000;
                            exe_sram_writedata = {reg2_data[7:0], 24'b0};
                        end
                        default: begin
                            wen = 0;
                        end
                    endcase
                end
                SH: begin
                    case (execute_sign.mem_addr[1])
                        1'b1: begin
                            wen   = 4'b1100;
                            exe_sram_writedata = {reg2_data[15:0], 16'b0};
                        end
                        1'b0: begin
                            wen   = 4'b0011;
                            exe_sram_writedata = {16'b0, reg2_data[15:0]};
                        end
                        default: begin
                            wen = 0;
                        end
                    endcase
                end
                SW: begin
                    exe_sram_writedata = reg2_data;
                    wen   = 4'b1111;
                    x = x+1;
                end
                SWL: begin

                    case (execute_sign.mem_addr[1:0])
                        2'b00: begin
                            exe_sram_writedata = reg2_data;
                            wen   = 4'b1111;
                        end
                        2'b01: begin
                            exe_sram_writedata = {8'b0, reg2_data[31:8]};
                            wen   = 4'b0111;
                        end
                        2'b10: begin
                            exe_sram_writedata = {16'b0, reg2_data[31:16]};
                            wen   = 4'b0011;
                        end
                        2'b11: begin
                            exe_sram_writedata = {24'b0, reg2_data[31:24]};
                            wen   = 4'b0001;
                        end
                        default: begin
                            exe_sram_writedata = 0;
                            wen   = 4'b0000;
                        end
                    endcase
                end
                SWR: begin
                    case (execute_sign.mem_addr[1:0])
                        2'b00: begin
                            exe_sram_writedata = {reg2_data[7:0], 24'b0};
                            wen   = 4'b1000;
                        end
                        2'b01: begin
                            exe_sram_writedata = {reg2_data[15:0], 16'b0};
                            wen   = 4'b1100;
                        end
                        2'b10: begin
                            exe_sram_writedata = {reg2_data[23:0], 8'b0};
                            wen = 4'b1110;
                            x = 1;
                        end
                        2'b11: begin
                            exe_sram_writedata = reg2_data;
                            wen   = 4'b1111;
                        end
                        default: begin
                            exe_sram_writedata = 0;
                            wen   = 4'b0000;
                        end
                    endcase

                end
                default: begin
                    exe_sram_writedata = 0;
                    wen   = 4'b0000;
                end
            endcase
        end else begin
            wen = 4'b0000;
            exe_sram_writedata = 0;
        end

    end

endmodule
