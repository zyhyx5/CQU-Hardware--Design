`include "my_mips.svh"
`include "define.svh"
module ctrl (
    input                  rst,
    input stall_req_sign_t stall_req,
    input flush_sign_t     flush_req,
    input control_sign_t   memory_sign,
    input control_sign_t   wb_sign,

    input exception_sign_t exception_sign,
    input exception_data_t exception_data,

    input word_t cp0_epc,

    output stall_sign_t s,
    output flush_sign_t f,
    output word_t       pc_exception


);

    logic      [3:0] x;
    cp0_wreq_t       cp0_wreq;
    assign cp0_wreq = wb_sign.cp0_wreq;

    always_comb begin
        if (!rst) begin
            s = '0;
            f = '0;
        end else begin
            s = '0;
            f = '0;

            //D阶段load型暂停， 在延迟槽阶段
            if (stall_req.stall_reqD_load && memory_sign.branch_flag == 1) begin
                {f.flushD, f.flushE} = 2'b11;

                //D阶段load型暂停， 不在延迟槽阶段
            end else if (stall_req.stall_reqD_load && memory_sign.branch_flag != 1) begin
                {s.stallW, s.stallM, s.stallE, s.stallD, s.stallF, s.stallPC} = 6'b001111;
                f.flushE = 1;
                //E阶段的madd指令暂停
            end else if (stall_req.stall_reqE) begin
                {s.stallW, s.stallM, s.stallE, s.stallD, s.stallF, s.stallPC} = 6'b001111;

                //当除法在延迟槽
            end else if (stall_req.stall_reqE_div && memory_sign.branch_flag == 1) begin
                s.stallPC_1 = 1;  //第一个周期不暂停，方便memory的jal写入信号
                {s.stallW, s.stallM, s.stallE, s.stallD, s.stallF, s.stallPC} = 6'b001111;
                f.flushD = 1;

                //当除法不在延迟槽
            end else if (stall_req.stall_reqE_div && memory_sign.branch_flag != 1&&!exception_sign.valid) begin
                {s.stallW, s.stallM, s.stallE, s.stallD, s.stallF, s.stallPC} = 6'b001111;

            end else if (stall_req.stall_reqE_div && memory_sign.branch_flag != 1&& exception_sign.valid) begin
                {s.stallW, s.stallM, s.stallE, s.stallD, s.stallF, s.stallPC} = 6'b001110;

                //当延迟槽指令不是除法指令
            end else if (!stall_req.stall_reqE_div && memory_sign.branch_flag == 1) begin
                {f.flushD, f.flushE} = 2'b11;
            end

        end

        if (!rst) begin
            pc_exception = '0;
        end else begin
            pc_exception = '0;
            if (exception_sign.valid || exception_sign.is_eret) begin
                if (exception_sign.valid) begin
                    pc_exception = 32'hbfc0_0380;
                    {f.flushD, f.flushE, f.flushM, f.flushW} = 4'b1111;
                end else begin
                    pc_exception = 0;
                end
                /*
                *一般情况下，epc中保存异常指令的地址，如果直接返回该地址，又会发生异常，
                顾通常异常处理程序会通过MTC0指令将EPC地址+4,当MTC0指令在wb阶段时，需要进行数据前推
                */

                if (exception_sign.is_eret && wb_sign.instr_name == MTC0 && cp0_wreq.we && cp0_wreq.waddr == `EPC) begin
                    pc_exception = cp0_wreq.wdata;
                    {f.flushD, f.flushE, f.flushM} = 3'b111;
                end else if (exception_sign.is_eret) begin
                    pc_exception = cp0_epc;
                    {f.flushD, f.flushE, f.flushM} = 3'b111;
                end

            end
        end

    end




endmodule
