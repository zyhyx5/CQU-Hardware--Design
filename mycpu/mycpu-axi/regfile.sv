`include "define.svh"
`include "my_mips.svh"

module regfile (

    input logic clk,
    input logic rst,

    //写端口
    input logic      we,
    input reg_addr_t waddr,
    input word_t     wdata,

    //读端口1
    input  logic      re1,
    input  reg_addr_t raddr1,
    output word_t     rdata1,

    //读端口2
    input  logic      re2,
    input  reg_addr_t raddr2,
    output word_t     rdata2,

    //在lw类型指令在E阶段的时候，由于数据需要在M阶段取出，所以这个时候需要暂停流水线
    output logic stall_reqD_load,

    //解决数据前推而需要的信号和数据
    input control_data_t control_data,
    input execute_data_t E_data,
    input memory_data_t  M_data,


    input control_sign_t E_sign,
    input control_sign_t M_sign
);

    logic stall_req1D, stall_req2D;
    assign stall_reqD_load = stall_req1D || stall_req2D;
    logic [31:0] regs[31:0] = '{default: '0};


    always @(posedge clk) begin
        regs[0] <= '0;
        if (!rst) begin
            regs[waddr] <= '0;
        end else begin
            if (we && (waddr != 0)) begin
                regs[waddr] <= wdata;
            end
        end
    end

    always_comb begin
        stall_req1D = 0;
        
        if (!rst) begin  //rst 复位选项
            rdata1 = '0;
        end else if ((raddr1 == 0) && re1) begin  //读的是零寄存器
            rdata1 = '0;
        end else if ((raddr1 == E_data.writereg) && E_sign.regwrite && re1 && E_sign.instr_class !=LOAD_) begin   //两个信号：wb的写信号和re1的读信号
            rdata1 = E_data.aluout;  //解决exe阶段的数据前推
        end else if ((raddr1 == E_data.writereg) && E_sign.regwrite && re1 && E_sign.instr_class ==LOAD_) begin   //两个信号：wb的写信号和re1的读信号
            stall_req1D = 1;  //解决exe阶段是lw时，进行暂停流水线
        end else if ((raddr1 == M_data.writereg) && M_sign.regwrite && re1) begin   //两个信号：wb的写信号和re1的读信号
            rdata1 = M_data.result;  //解决men阶段的数据前推
        end else if ((raddr1 == waddr) && we && re1) begin   //两个信号：wb的写信号和re1的读信号
            rdata1 = wdata;  //解决wb阶段的数据前推
        end else if (re1 == 1'b0) begin
            rdata1 = control_data.imm;
        end else if (re1) begin  //正常读寄存器
            rdata1 = regs[raddr1];
        end else begin
            rdata1 = '0;  //其他情况
        end

        stall_req2D = 0;
        if (!rst) begin  //rst 复位选项
            rdata2 = '0;
        end else if ((raddr2==0) && re2) begin  //读的是零寄存器
            rdata2 = '0;
        end else if ((raddr2 == E_data.writereg) && E_sign.regwrite && re2 && E_sign.instr_class !=LOAD_) begin   //两个信号：wb的写信号和re1的读信号
            rdata2 = E_data.aluout;  //解决exe阶段的数据前推
        end else if ((raddr2 == E_data.writereg) && E_sign.regwrite && re2 && E_sign.instr_class ==LOAD_) begin   //两个信号：wb的写信号和re1的读信号
            stall_req2D = 1;  //解决exe阶段是lw时，进行暂停流水线
        end else if ((raddr2 == M_data.writereg) && M_sign.regwrite && re2) begin   //两个信号：wb的写信号和re1的读信号
            rdata2 = M_data.result;  //解决mem阶段的数据前推
        end else if ((raddr2 == waddr) && we && re2) begin   //两个信号：wb的写信号和re1的读信号
            rdata2 = wdata;  //解决wb阶段的数据前推
        end else if (re2 == 1'b0) begin
            rdata2 = control_data.imm;
        end else if (re2) begin  //正常读寄存器
            rdata2 = regs[raddr2];
        end else begin
            rdata2 = '0;  //其他情况
        end

    end



endmodule
