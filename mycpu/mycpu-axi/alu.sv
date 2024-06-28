`include "my_mips.svh"
`include "define.svh"


module ALU (
    input logic          rst,
    input logic          clk,
    input word_t         a,
    input word_t         b,
    input control_sign_t execute_sign,
    input control_sign_t memory_sign,
    input double_word_t  HILO,


    output word_t        c,
    output double_word_t cc,
    output logic         overflow,
    output logic         stall_reqE




);
    logic [4:0] x = 0;
    logic [4:0] shamt;
    assign shamt = a[4:0];
    logic         [32:0] temp;
    double_word_t        hilo_temp;
    always_comb begin
        overflow = 0;
        temp = '0;

        case (execute_sign.alufunc)

            //1. 加法
            ALU_ADD: begin
                c = a + b;
                temp = {a[31], a} + {b[31], b};
                overflow = (temp[32] != temp[31]);
            end
            ALU_ADDU: begin
                c = a + b;
            end
            //2. 减法
            ALU_SUB: begin
                c = a - b;
                temp = {a[31], a} - {b[31], b};
                overflow = (temp[32] != temp[31]);
            end
            ALU_SUBU: begin
                c = a - b;
            end

            //3. 置位操作
            ALU_SLTU: begin
                c = (a < b) ? 32'b01 : 32'b00;
            end
            ALU_SLT: begin
                c = (signed'(a) < signed'(b)) ? 32'b1 : 32'b0;
            end

            //6. 计数操作
            ALU_CLZ: begin
                c = a[31] ? 0 : a[30] ? 1 : a[29] ? 2 :
					a[28] ? 3 : a[27] ? 4 : a[26] ? 5 :
					a[25] ? 6 : a[24] ? 7 : a[23] ? 8 : 
					a[22] ? 9 : a[21] ? 10 : a[20] ? 11 :
					a[19] ? 12 : a[18] ? 13 : a[17] ? 14 : 
					a[16] ? 15 : a[15] ? 16 : a[14] ? 17 : 
					a[13] ? 18 : a[12] ? 19 : a[11] ? 20 :
					a[10] ? 21 : a[9] ? 22 : a[8] ? 23 : 
					a[7] ? 24 : a[6] ? 25 : a[5] ? 26 : 
					a[4] ? 27 : a[3] ? 28 : a[2] ? 29 : 
					a[1] ? 30 : a[0] ? 31 : 32 ;
            end
            ALU_CLO: begin
                c = !a[31] ? 0 : !a[30] ? 1 : !a[29] ? 2 :
					!a[28] ? 3 : !a[27] ? 4 : !a[26] ? 5 :
					!a[25] ? 6 : !a[24] ? 7 : !a[23] ? 8 : 
					!a[22] ? 9 : !a[21] ? 10 : !a[20] ? 11 :
					!a[19] ? 12 : !a[18] ? 13 : !a[17] ? 14 : 
					!a[16] ? 15 : !a[15] ? 16 : !a[14] ? 17 : 
					!a[13] ? 18 : !a[12] ? 19 : !a[11] ? 20 :
					!a[10] ? 21 : !a[9] ? 22 : !a[8] ? 23 : 
					!a[7] ? 24 : !a[6] ? 25 : !a[5] ? 26 : 
					!a[4] ? 27 : !a[3] ? 28 : !a[2] ? 29 : 
					!a[1] ? 30 : !a[0] ? 31 : 32 ;
            end

            ALU_AND: begin
                c = a & b;
            end
            ALU_OR: begin
                c = a | b;
            end
            ALU_SLL: begin
                c = b << shamt;
            end
            ALU_SRL: begin
                c = b >> shamt;
            end
            ALU_SRA: begin
                c = signed'(b) >>> shamt;
            end


            ALU_NOR: begin
                c = ~(a | b);
            end
            ALU_XOR: begin
                c = a ^ b;
            end

            ALU_LUI: begin
                c = {b[15:0], 16'b0};
            end

            ALU_PASSB: begin
                c = b;
            end
            ALU_PASSA: begin
                c = a;
            end
            default: begin
                c = '0;
            end
        endcase

        case (execute_sign.instr_name)
            MUL: begin
                c = signed'(a) * signed'(b);
            end
            MULT: begin
                cc = signed'(a) * signed'(b);
            end
            MULTU: begin
                cc = (a) * (b);
            end

            // MADD: begin

            //     if (!execute_sign.exe_cnt_0) begin
            //         hilo_temp = signed'(a) * signed'(b);
            //         execute_sign.exe_cnt_0 = 1;
            //         stall_reqE = 1'b1;

            //     end else if (memory_sign.exe_cnt_0) begin
            //         execute_sign.exe_cnt_0 = 2'b00;
            //         memory_sign.exe_cnt_0 = 2'b00;

            //         stall_reqE = 1'b0;
            //         cc = hilo_temp + HILO;
            //     end

            // end
            // MADDU: begin
            //     if (!execute_sign.exe_cnt_0) begin
            //         hilo_temp = (a) * (b);
            //         execute_sign.exe_cnt_0 = 2'b01;
            //         stall_reqE = 1'b1;
            //     end else if (memory_sign.exe_cnt_0) begin
            //         execute_sign.exe_cnt_0 = 2'b00;
            //         memory_sign.exe_cnt_0 = 2'b00;
            //         stall_reqE = 1'b0;
            //         cc = hilo_temp + HILO;
            //     end
            // end
            // MSUB: begin
            //     if (!execute_sign.exe_cnt_0) begin
            //         hilo_temp = signed'(a) * signed'(b);
            //         execute_sign.exe_cnt_0 = 2'b01;
            //         stall_reqE = 1'b1;
            //     end else if (memory_sign.exe_cnt_0) begin
            //         execute_sign.exe_cnt_0 = 2'b00;
            //         memory_sign.exe_cnt_0 = 2'b00;
            //         stall_reqE = 1'b0;
            //         cc = HILO - hilo_temp;
            //     end
            // end
            // MSUBU: begin
            //     if (!execute_sign.exe_cnt_0) begin
            //         hilo_temp = (a) * (b);
            //         execute_sign.exe_cnt_0 = 2'b01;
            //         stall_reqE = 1'b1;
            //     end else if (memory_sign.exe_cnt_0) begin
            //         execute_sign.exe_cnt_0 = 2'b00;
            //         memory_sign.exe_cnt_0 = 2'b00;
            //         stall_reqE = 1'b0;
            //         cc = HILO - hilo_temp;
            //     end
            // end

        endcase
    end
endmodule
