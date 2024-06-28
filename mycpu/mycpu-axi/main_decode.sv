`include "my_mips.svh"
`include "define.svh"

module main_decode (
    input                 rst,
    input  decode_data_t  decode_data,
    input  control_sign_t execute_sign,
    output control_sign_t clt,
    output control_data_t cdt
    // input  wire           zero
);

    logic [ 5:0] op;
    logic [ 4:0] offset;
    logic [ 5:0] funct;
    logic [ 4:0] rt;
    logic [ 4:0] rd;
    logic [15:0] immediate;
    word_t imm_sll2_signedext, pc_plus_8, pc_plus_4;
    word_t instr;
    // logic [39:0] ascii;
    always_comb begin
        op = decode_data.instr[31:26];
        offset = decode_data.instr[10:6];
        funct = decode_data.instr[5:0];
        rt = decode_data.instr[20:16];
        rd = decode_data.instr[15:11];
        immediate = decode_data.instr[15:0];
        pc_plus_8 = decode_data.pc + 8;
        pc_plus_4 = decode_data.pc + 4;
        imm_sll2_signedext = {{14{decode_data.instr[15]}}, decode_data.instr[15:0], 2'b00};
        instr = decode_data.instr;
    end

    // instdec instdec (
    //     .instr(decode_data.instr),
    //     .ascii(ascii)
    // );



    always_comb begin
        if (!rst) begin
            clt = '0;
            clt.cp0_wreq = 0;
            clt.cp0_rreq = 0;
            cdt = '0;
        end else if (execute_sign.next_delayslot) begin
            clt = '0;
            cdt = '0;
            clt.now_delayslot = 1;
            cdt.imm = '0;
            clt.annul_div = 1'b1;  //必须要有，每条指令都存在取消除法操作，否则会出错
            clt.cp0_wreq = 0;
            clt.cp0_rreq = 0;
            cdt.writereg = instr[15:11];  //默认写地址是rd
            clt.valid = 1;
            // clt.ascii = ascii;
        end else begin
            clt = '0;
            cdt.imm = '0;
            clt.cp0_wreq = 0;
            clt.annul_div = 1'b1;  //必须要有，每条指令都存在取消除法操作，否则会出错
            clt.cp0_rreq = 0;
            cdt.writereg = instr[15:11];  //默认写地址是rd
            clt.valid = 1;
            // clt.ascii = ascii;
        end
        case (op)
            `R1_INST: begin
                case (offset)
                    5'b00000: begin
                        case (funct)
                            `FUNC_OR: begin
                                clt.regwrite = 1'b1;
                                clt.alufunc = ALU_OR;

                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                                clt.instr_class = LOGIC_;
                                clt.instr_name = OR;
                            end
                            `FUNC_AND: begin
                                clt.regwrite = 1'b1;
                                clt.alufunc = ALU_AND;

                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                                clt.instr_class = LOGIC_;
                                clt.instr_name = AND;
                            end
                            `FUNC_XOR: begin
                                clt.regwrite = 1'b1;
                                clt.alufunc = ALU_XOR;

                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                                clt.instr_class = LOGIC_;
                                clt.instr_name = XOR;
                            end
                            `FUNC_NOR: begin  //按位或非运算
                                clt.regwrite = 1'b1;
                                clt.alufunc = ALU_NOR;

                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                                clt.instr_class = LOGIC_;
                                clt.instr_name = NOR;
                            end

                            `FUNC_SLLV: begin  //逻辑左移运算
                                clt.regwrite = 1'b1;
                                clt.alufunc = ALU_SLL;

                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                                clt.instr_class = SHIFT_;
                                clt.instr_name = SLLV;
                            end
                            `FUNC_SRLV: begin  //逻辑右移
                                clt.regwrite = 1'b1;
                                clt.alufunc = ALU_SRL;

                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                                clt.instr_class = SHIFT_;
                                clt.instr_name = SRLV;
                            end
                            `FUNC_SRAV: begin  //算术右移
                                clt.regwrite = 1'b1;
                                clt.alufunc = ALU_SRA;

                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                                clt.instr_class = SHIFT_;
                                clt.instr_name = SRAV;
                            end
                            `FUNC_SYNC: begin
                                clt.regwrite = 1'b0;
                                clt.alufunc = sync;
                                clt.reg1_read = 1'b0;
                                clt.reg2_read = 1'b1;
                                clt.instr_class = NOP_;
                                clt.instr_name = SYNC;
                            end
                            `FUNC_MFHI: begin
                                clt.regwrite = 1'b1;
                                clt.alufunc = ALU_PASSB;
                                clt.reg1_read = 1'b0;
                                clt.reg2_read = 1'b0;
                                clt.hitoreg = 1'b1;
                                clt.instr_class = MOVE_;
                                clt.instr_name = MFHI;
                            end
                            `FUNC_MFLO: begin
                                clt.regwrite = 1'b1;
                                clt.alufunc = ALU_PASSB;
                                clt.reg1_read = 1'b0;
                                clt.reg2_read = 1'b0;
                                clt.lotoreg = 1'b1;
                                clt.instr_class = MOVE_;
                                clt.instr_name = MFLO;
                            end
                            `FUNC_MTHI: begin
                                clt.regwrite = 1'b0;
                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b0;
                                clt.hiwrite = 1'b1;
                                clt.instr_class = MOVE_;
                                clt.instr_name = MTHI;
                            end
                            `FUNC_MTLO: begin
                                clt.regwrite = 1'b0;
                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b0;
                                clt.lowrite = 1'b1;
                                clt.instr_class = MOVE_;
                                clt.instr_name = MTLO;
                            end
                            `FUNC_MOVN: begin
                                clt.alufunc = ALU_PASSA;
                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                                clt.instr_class = MOVE_;
                                clt.instr_name = MOVN;
                                if (decode_data.RD2_data) begin
                                    clt.regwrite = 1'b1;
                                end else begin
                                    clt.regwrite = 1'b0;
                                end
                            end
                            `FUNC_MOVZ: begin
                                clt.alufunc = ALU_PASSA;
                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                                clt.instr_class = MOVE_;
                                clt.instr_name = MOVZ;
                                if (!decode_data.RD2_data) begin
                                    clt.regwrite = 1'b1;
                                end else begin
                                    clt.regwrite = 1'b0;
                                end
                            end
                            `FUNC_SLT: begin
                                clt.regwrite = 1'b1;
                                clt.alufunc = ALU_SLT;
                                clt.instr_class = ARITHMETIC_;
                                clt.instr_name = SLT;
                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                            end
                            `FUNC_SLTU: begin
                                clt.regwrite = 1'b1;
                                clt.alufunc = ALU_SLTU;
                                clt.instr_class = ARITHMETIC_;
                                clt.instr_name = SLTU;
                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                            end
                            `FUNC_ADD: begin
                                clt.regwrite = 1'b1;
                                clt.alufunc = ALU_ADD;
                                clt.instr_class = ARITHMETIC_;
                                clt.instr_name = ADD;
                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                            end
                            `FUNC_ADDU: begin
                                clt.regwrite = 1'b1;
                                clt.alufunc = ALU_ADDU;
                                clt.instr_class = ARITHMETIC_;
                                clt.instr_name = ADDU;
                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                            end
                            `FUNC_SUB: begin
                                clt.regwrite = 1'b1;
                                clt.alufunc = ALU_SUB;
                                clt.instr_class = ARITHMETIC_;
                                clt.instr_name = SUB;
                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                            end
                            `FUNC_SUBU: begin
                                clt.regwrite = 1'b1;
                                clt.alufunc = ALU_SUBU;
                                clt.instr_class = ARITHMETIC_;
                                clt.instr_name = SUBU;
                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                            end
                            `FUNC_MULT: begin
                                clt.regwrite = 1'b0;
                                clt.alufunc = ALU_MUL;
                                clt.instr_class = ARITHMETIC_;
                                clt.instr_name = MULT;

                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                                clt.hiwrite = 1'b1;
                                clt.lowrite = 1'b1;
                            end
                            `FUNC_MULTU: begin
                                clt.regwrite = 1'b0;
                                clt.alufunc = ALU_MULU;
                                clt.instr_class = ARITHMETIC_;
                                clt.instr_name = MULTU;
                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                                clt.hiwrite = 1'b1;
                                clt.lowrite = 1'b1;
                            end
                            `FUNC_DIV: begin
                                clt.regwrite = 1'b0;
                                clt.instr_name = DIV;
                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                                clt.hiwrite = 1'b1;
                                clt.lowrite = 1'b1;
                                clt.is_signed = 1'b1;
                                clt.start_div = 1'b1;
                                clt.annul_div = 1'b0;
                                clt.ready_div = 1'b0;
  
                            end
                            `FUNC_DIVU: begin
                                clt.regwrite = 1'b0;
                                clt.instr_name = DIVU;
                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b1;
                                clt.hiwrite = 1'b1;
                                clt.lowrite = 1'b1;
                                clt.is_signed = 1'b0;
                                clt.start_div = 1'b1;
                                clt.annul_div = 1'b0;
                                clt.ready_div = 1'b0;
          
                            end
                            `FUNC_JR: begin
                                clt.regwrite = 1'b0;
                                clt.instr_name = JR;
                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b0;
                                clt.branch_target_address = decode_data.RD1_data;
                                clt.branch_flag = 1'b1;


                                clt.next_delayslot = 1'b1;
                                clt.now_delayslot = 1'b0;
                            end
                            `FUNC_JALR: begin
                                clt.regwrite = 1'b1;
                                clt.alufunc = ALU_PASSA;
                                clt.instr_name = JALR;
                                clt.reg1_read = 1'b1;
                                clt.reg2_read = 1'b0;
                                clt.link_addr = pc_plus_8;
                                clt.instr_class = JAL_;
                                clt.branch_target_address = decode_data.RD1_data;
                                clt.branch_flag = 1'b1;
                                clt.next_delayslot = 1'b1;
                                clt.now_delayslot = 1'b0;
                            end
                            `FUNC_BREAK: begin
                                clt.alufunc = ALU_PASSA;
                                clt.instr_name = BREAK;
                            end
                            `FUNC_SYSCALL: begin
                                clt.alufunc = ALU_PASSA;
                                clt.instr_name = SYSCALL;
                            end

                            default: begin
                                clt.valid = 0;
                            end
                        endcase
                    end
                    default: begin
                        clt.valid = 0;
                    end
                endcase
            end
            `OP_ORI: begin
                clt.regwrite = 1'b1;
                clt.alufunc = ALU_OR;
                 
                clt.instr_class = LOGIC_;
                clt.instr_name = ORI;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b0;
                cdt.imm = {16'h0, immediate};  //cdt.imm是一个32位的立即数。
                cdt.writereg = rt;
            end
            `OP_ANDI: begin
                clt.regwrite = 1'b1;
                clt.alufunc = ALU_AND;
                clt.instr_class = LOGIC_;
                clt.instr_name = ANDI;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b0;
                cdt.imm = {16'h0, immediate};
                cdt.writereg = rt;
            end
            `OP_XORI: begin
                clt.regwrite = 1'b1;
                clt.alufunc = ALU_XOR;
                clt.instr_class = LOGIC_;
                clt.instr_name = XORI;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b0;
                cdt.imm = {16'h0, immediate};
                cdt.writereg = rt;
            end
            `OP_LUI: begin
                clt.regwrite = 1'b1;
                clt.alufunc = ALU_LUI;
                clt.instr_class = LOGIC_;
                clt.instr_name = LUI;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b0;
                cdt.imm = {16'b0, immediate};
                cdt.writereg = rt;
            end
            `OP_PREF: begin
                clt.regwrite = 0;
                clt.instr_class = NOP_;
                clt.instr_name = PREF;
                clt.reg1_read = 1'b0;
                clt.reg2_read = 1'b0;
            end
            `OP_SLTI: begin
                clt.regwrite = 1'b1;
                clt.alufunc = ALU_SLT;
                clt.instr_class = ARITHMETIC_;
                clt.instr_name = SLTI;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b0;
                cdt.imm = {{16{immediate[15]}}, immediate};
                cdt.writereg = rt;
            end
            `OP_SLTIU: begin
                clt.regwrite = 1'b1;
                clt.alufunc = ALU_SLTU;
                clt.instr_class = ARITHMETIC_;
                clt.instr_name = SLTIU;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b0;
                cdt.imm = {{16{immediate[15]}}, immediate};
                cdt.writereg = rt;
            end
            `OP_ADDI: begin
                clt.regwrite = 1'b1;
                clt.alufunc = ALU_ADD;
                clt.instr_class = ARITHMETIC_;

                clt.instr_name = ADDI;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b0;
                cdt.imm = {{16{immediate[15]}}, immediate};
                cdt.writereg = rt;
            end
            `OP_ADDIU: begin
                clt.regwrite = 1'b1;
                clt.alufunc = ALU_ADDU;
                clt.instr_class = ARITHMETIC_;
                clt.instr_name = ADDIU;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b0;
                cdt.imm = {{16{immediate[15]}}, immediate};
                cdt.writereg = rt;
            end
            `OP_J: begin
                clt.regwrite = 1'b0;
                clt.instr_name = J;
                clt.reg1_read = 1'b0;
                clt.reg2_read = 1'b0;
                clt.branch_target_address = {pc_plus_4[31:28], instr[25:0], 2'b00};
                clt.branch_flag = 1'b1;
                clt.next_delayslot = 1'b1;
                clt.now_delayslot = 1'b0;
            end
            `OP_JAL: begin
                clt.regwrite = 1'b1;
                clt.instr_name = JAL;
                clt.alufunc = ALU_PASSA;
                clt.reg1_read = 1'b0;
                clt.reg2_read = 1'b0;
                cdt.writereg = 5'b11111;
                clt.link_addr = pc_plus_8;
                clt.instr_class = JAL_;
                clt.branch_target_address = {pc_plus_4[31:28], instr[25:0], 2'b00};
                clt.branch_flag = 1'b1;
                clt.next_delayslot = 1'b1;
                clt.now_delayslot = 1'b0;
            end
            `OP_BEQ: begin
                clt.regwrite   = 1'b0;
                clt.instr_name = BEQ;
                clt.reg1_read  = 1'b1;
                clt.reg2_read  = 1'b1;
                clt.next_delayslot = 1'b1;
                if (decode_data.RD1_data == decode_data.RD2_data) begin
                    clt.branch_target_address = pc_plus_4 + imm_sll2_signedext;
                    clt.branch_flag = 1'b1;
                    clt.now_delayslot = 1'b0;
                end
            end
            `OP_BGTZ: begin
                clt.regwrite   = 1'b0;
                clt.instr_name = BGTZ;
                clt.reg1_read  = 1'b1;
                clt.reg2_read  = 1'b0;
                clt.next_delayslot = 1'b1;
                if (decode_data.RD1_data && !decode_data.RD1_data[31]) begin
                    clt.branch_target_address = pc_plus_4 + imm_sll2_signedext;
                    clt.branch_flag = 1'b1;
                    clt.now_delayslot = 1'b0;
                end
            end
            `OP_BLEZ: begin
                clt.regwrite   = 1'b0;
                clt.instr_name = BLEZ;
                clt.reg1_read  = 1'b1;
                clt.reg2_read  = 1'b0;
                clt.next_delayslot = 1'b1;
                if (decode_data.RD1_data == 0 || decode_data.RD1_data[31]) begin
                    clt.branch_target_address = pc_plus_4 + imm_sll2_signedext;
                    clt.branch_flag = 1'b1; 
                    clt.now_delayslot = 1'b0;
                end
            end
            `OP_BNE: begin
                clt.regwrite   = 1'b0;
                clt.instr_name = BNE;
                clt.reg1_read  = 1'b1;
                clt.reg2_read  = 1'b1;
                clt.next_delayslot = 1'b1;
                if (decode_data.RD1_data != decode_data.RD2_data) begin
                    clt.branch_target_address = pc_plus_4 + imm_sll2_signedext;
                    clt.branch_flag = 1'b1;
                    clt.now_delayslot = 1'b0;
                end
            end
            `OP_LB: begin
                clt.regwrite = 1'b1;
                clt.memtoreg = 1'b1;
                clt.instr_name = LB;
                clt.instr_class = LOAD_;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b0;
                cdt.writereg = rt;
                cdt.imm = rt;
                clt.mem_addr = {{16{immediate[15]}}, immediate} + decode_data.RD1_data;
            end
            `OP_LBU: begin
                clt.regwrite = 1'b1;
                clt.memtoreg = 1'b1;
                clt.instr_name = LBU;
                clt.instr_class = LOAD_;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b0;
                cdt.writereg = rt;
                clt.mem_addr = {{16{immediate[15]}}, immediate} + decode_data.RD1_data;
            end

            `OP_LH: begin
                clt.regwrite = 1'b1;
                clt.memtoreg = 1'b1;
                clt.instr_name = LH;
                clt.instr_class = LOAD_;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b0;
                cdt.writereg = rt;
                clt.mem_addr = {{16{immediate[15]}}, immediate} + decode_data.RD1_data;
            end
            `OP_LHU: begin
                clt.regwrite = 1'b1;
                clt.memtoreg = 1'b1;
                clt.instr_name = LHU;
                clt.instr_class = LOAD_;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b0;
                cdt.writereg = rt;
                clt.mem_addr = {{16{immediate[15]}}, immediate} + decode_data.RD1_data;
            end
            `OP_LW: begin
                clt.regwrite = 1'b1;
                clt.memtoreg = 1'b1;
                clt.instr_name = LW;
                clt.instr_class = LOAD_;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b0;
                cdt.writereg = rt;
                clt.mem_addr = {{16{immediate[15]}}, immediate} + decode_data.RD1_data;
            end
            `OP_LWL: begin
                clt.regwrite = 1'b1;
                clt.memtoreg = 1'b1;
                clt.instr_name = LWL;
                clt.instr_class = LOAD_;
                clt.reg1_read = 1'b1;
  
                clt.reg2_read = 1'b1;
                cdt.writereg = rt;
                clt.mem_addr = {{16{immediate[15]}}, immediate} + decode_data.RD1_data;

            end
            `OP_LWR: begin
                clt.regwrite = 1'b1;
                clt.memtoreg = 1'b1;
                clt.instr_name = LWR;
                clt.instr_class = LOAD_;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b1;
                cdt.writereg = rt;
                clt.mem_addr = {{16{immediate[15]}}, immediate} + decode_data.RD1_data;
            end
            `OP_SB: begin
                clt.regwrite = 1'b0;
                clt.instr_name = SB;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b1;
                clt.instr_class = STORE_;
                clt.mem_addr = {{16{immediate[15]}}, immediate} + decode_data.RD1_data;
            end
            `OP_SH: begin
                clt.regwrite = 1'b0;
                clt.instr_name = SH;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b1;
                clt.instr_class = STORE_;
                clt.mem_addr = {{16{immediate[15]}}, immediate} + decode_data.RD1_data;
            end
            `OP_SH: begin
                clt.regwrite = 1'b0;
                clt.instr_name = SH;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b1;
                clt.instr_class = STORE_;
                clt.mem_addr = {{16{immediate[15]}}, immediate} + decode_data.RD1_data;
            end
            `OP_SW: begin
                clt.regwrite = 1'b0;
                clt.instr_name = SW;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b1;

                clt.instr_class = STORE_;
                clt.mem_addr = {{16{immediate[15]}}, immediate} + decode_data.RD1_data;
            end
            `OP_SWL: begin
                clt.regwrite = 1'b0;
                clt.instr_name = SWL;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b1;
                clt.instr_class = STORE_;
                clt.mem_addr = {{16{immediate[15]}}, immediate} + decode_data.RD1_data;
            end
            `OP_SWR: begin
                clt.regwrite = 1'b0;
                clt.instr_name = SWR;
                clt.reg1_read = 1'b1;
                clt.reg2_read = 1'b1;
                clt.instr_class = STORE_;
                clt.mem_addr = {{16{immediate[15]}}, immediate} + decode_data.RD1_data;
            end
            `OP_ERET: begin
                case (instr[25:21])
                    `C_ERET: begin
                        clt.regwrite = 1'b0;
                        clt.instr_name = ERET;

                    end
                    `C_MFC0: begin
                        clt.regwrite = 1'b1;
                        clt.alufunc = ALU_PASSA;

                        clt.instr_class = MOVE_;
                        clt.instr_name = MFC0;
                        clt.reg1_read = 1'b0;
                        clt.reg2_read = 1'b0;

                        cdt.writereg = rt;
                        clt.cp0_rreq.rsel = '0;
                        clt.cp0_rreq.raddr = rd;
                    end
                    `C_MTC0: begin

                        clt.regwrite = 1'b0;

                        clt.alufunc = ALU_PASSB;
                        clt.instr_class = MOVE_;
                        clt.instr_name = MTC0;
                        clt.reg1_read = 1'b0;
                        clt.reg2_read = 1'b1;

                        clt.cp0_wreq.we = 1'b1;
                        clt.cp0_wreq.wsel = 0;
                        clt.cp0_wreq.waddr = rd;
                        clt.cp0_wreq.wdata = decode_data.RD2_data;
                    end
                    default:begin
                        clt.valid = 0;
                    end

                endcase
            end

            `REGIMM_INST: begin
                case (rt)
                    `RT_BGEZ: begin
                        clt.regwrite   = 1'b0;
                        clt.instr_name = BGEZ;
                        clt.reg1_read  = 1'b1;
                        clt.reg2_read  = 1'b0;
                        clt.next_delayslot = 1'b1;
                        if (!decode_data.RD1_data[31]) begin
                            clt.branch_target_address = pc_plus_4 + imm_sll2_signedext;
                            clt.branch_flag = 1'b1;
                            clt.now_delayslot = 1'b0;
                        end
                    end
                    `RT_BGEZAL: begin
                        clt.regwrite = 1'b1;
                        clt.instr_name = BGEZAL;
                        clt.alufunc = ALU_PASSA;
                        clt.reg1_read = 1'b1;
                        clt.reg2_read = 1'b0;
                        clt.link_addr = pc_plus_8;
                        clt.instr_class = JAL_;
                        cdt.writereg = 5'b11111;
                        clt.next_delayslot = 1'b1;
                        if (!decode_data.RD1_data[31]) begin
                            clt.branch_target_address = pc_plus_4 + imm_sll2_signedext;
                            clt.branch_flag = 1'b1;
                            clt.now_delayslot = 1'b0;
                        end
                    end
                    `RT_BLTZ: begin
                        clt.regwrite   = 1'b0;
                        clt.instr_name = BLTZ;
                        clt.reg1_read  = 1'b1;
                        clt.reg2_read  = 1'b0;
                        clt.next_delayslot = 1'b1;
                        if (decode_data.RD1_data[31]) begin
                            clt.branch_target_address = pc_plus_4 + imm_sll2_signedext;
                            clt.branch_flag = 1'b1;
                            clt.now_delayslot = 1'b0;
                        end
                    end
                    `RT_BLTZAL: begin
                        clt.regwrite = 1'b1;
                        clt.instr_name = BLTZAL;
                        clt.alufunc = ALU_PASSA;
                        clt.reg1_read = 1'b1;
                        clt.reg2_read = 1'b0;
                        clt.link_addr = pc_plus_8;
                        clt.instr_class = JAL_;
                        cdt.writereg = 5'b11111;
                        clt.next_delayslot = 1'b1;
                        if (decode_data.RD1_data[31]) begin
                            clt.branch_target_address = pc_plus_4 + imm_sll2_signedext;
                            clt.branch_flag = 1'b1;
                            clt.now_delayslot = 1'b0;
                        end
                    end

                    default: begin
                        clt.valid = 0;
                    end
                endcase
            end

            `R2_INST: begin
                case (funct)
                    `FUNC_CLZ: begin
                        clt.regwrite = 1'b1;
                        clt.alufunc = ALU_CLZ;
                        clt.instr_class = ARITHMETIC_;
                        clt.instr_name = CLZ;
                        clt.reg1_read = 1'b1;
                        clt.reg2_read = 1'b0;
                    end
                    `FUNC_CLO: begin
                        clt.regwrite = 1'b1;
                        clt.alufunc = ALU_CLO;
                        clt.instr_class = ARITHMETIC_;
                        clt.instr_name = CLO;
                        clt.reg1_read = 1'b1;
                        clt.reg2_read = 1'b0;
                    end
                    `FUNC_MUL: begin
                        clt.regwrite = 1'b1;
                        clt.alufunc = ALU_MUL;
                        clt.instr_class = MUL_;
                        clt.instr_name = MUL;
                        clt.reg1_read = 1'b1;
                        clt.reg2_read = 1'b1;
                    end
                    `FUNC_MADD: begin
                        clt.regwrite = 1'b0;
                        clt.instr_name = MADD;
                        clt.reg1_read = 1'b1;
                        clt.reg2_read = 1'b1;
                        clt.hiwrite = 1'b1;
                        clt.lowrite = 1'b1;
                        clt.exe_cnt_0 = 2'b0;
                    end
                    `FUNC_MADDU: begin
                        clt.regwrite = 1'b0;
                        clt.instr_name = MADDU;
                        clt.reg1_read = 1'b1;
                        clt.reg2_read = 1'b1;
                        clt.hiwrite = 1'b1;
                        clt.lowrite = 1'b1;
                        clt.exe_cnt_0 = 2'b0;
                    end
                    `FUNC_MSUB: begin
                        clt.regwrite = 1'b0;
                        clt.instr_name = MSUB;
                        clt.reg1_read = 1'b1;
                        clt.reg2_read = 1'b1;
                        clt.hiwrite = 1'b1;
                        clt.lowrite = 1'b1;
                        clt.exe_cnt_0 = 2'b0;
                    end
                    `FUNC_MSUBU: begin
                        clt.regwrite = 1'b0;
                        clt.instr_name = MSUBU;
                        clt.reg1_read = 1'b1;
                        clt.reg2_read = 1'b1;
                        clt.hiwrite = 1'b1;
                        clt.lowrite = 1'b1;
                        clt.exe_cnt_0 = 2'b0;
                    end
                    default: begin
                        clt.valid = 0;
                    end
                endcase
            end
            default: begin
                clt.valid = 0;
            end
        endcase


        if (instr[31:21] == 11'b0000_0000_000) begin

            //sll instruction
            if (funct == `FUNC_SLL) begin  //sll
                clt.regwrite = 1'b1;
                clt.alufunc = ALU_SLL;
                clt.instr_class = SHIFT_;
                clt.reg1_read = 1'b0;
                clt.reg2_read = 1'b1;
                cdt.imm[4:0] = {immediate[10:6]};
                cdt.writereg = rd;
                clt.valid = 1;
                if (offset == 6'b000000) begin
                    clt.instr_name = NOP;
                end else begin
                    clt.instr_name = SLL;
                end
                //srl instruction
            end else if (funct == `FUNC_SRL) begin  //srl
                clt.regwrite = 1'b1;
                clt.alufunc = ALU_SRL;
                clt.instr_class = SHIFT_;
                clt.instr_name = SRL;
                clt.reg1_read = 1'b0;
                clt.reg2_read = 1'b1;
                cdt.imm[4:0] = {immediate[10:6]};
                cdt.writereg = rd;
                clt.valid = 1;
                //sra instruction
            end else if (funct == `FUNC_SRA) begin  //sra
                clt.regwrite = 1'b1;
                clt.alufunc = ALU_SRA;
                clt.instr_class = SHIFT_;
                clt.instr_name = SRA;
                clt.reg1_read = 1'b0;
                clt.reg2_read = 1'b1;
                cdt.imm[4:0] = {immediate[10:6]};
                cdt.writereg = rd;
                clt.valid = 1;
            end
        end
    end
endmodule
