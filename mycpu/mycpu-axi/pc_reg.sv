`include "my_mips.svh"
`include "define.svh"
module pc_reg (
    input wire clk,
    input wire rst,

    input control_sign_t memory_sign,

    input stall_sign_t stall,
    input word_t       pc_exception,

    output word_t pc_new 

);

    always @(negedge clk) begin
        if (!rst) begin
            pc_new <= 32'hbfc00000;
        end else begin
            if (stall.stallPC == 0) begin
                if (memory_sign.branch_flag&&!pc_exception) begin
                    pc_new <= memory_sign.branch_target_address;
                end else if(pc_exception) begin
                    pc_new <= pc_exception;
                end else begin
                    pc_new <= pc_new + 4;
                end
            end else if (stall.stallPC && stall.stallPC_1) begin
                if (memory_sign.branch_flag) begin
                    pc_new <= memory_sign.branch_target_address;
                end
            end
        end


    end


endmodule
