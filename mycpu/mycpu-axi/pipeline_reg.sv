`include "my_interface.svh"
`include "my_mips.svh"
`include "define.svh"
module f_d_reg (
    input  wire         clk,
    input  wire         rst,
    input  wire         stallD,
    input  wire         clear,
    input  fetch_data_t data_in,
    output fetch_data_t data_out

);

    always_ff @(posedge clk) begin
        if (!rst) begin
            data_out <= 0;
        end else if (clear) begin
            data_out <= 0;
        end else if (!stallD) begin
            data_out <= data_in;
        end
    end
endmodule

module d_e_reg (
    input  logic          clk,
    input  logic          rst,
    input  logic          stallE,
    input  logic          clear,
    input  decode_data_t  data_in,
    input  control_sign_t sign_in,
    output control_sign_t sign_out,
    output decode_data_t  data_out

);

    always_ff @(posedge clk) begin
        if (!rst) begin
            data_out <= 0;
            sign_out <= 0;
        end else if (clear) begin
            data_out <= 0;
            sign_out <= 0;
        end else if (!stallE) begin
            data_out <= data_in;
            sign_out <= sign_in;
        end
    end
endmodule

module e_m_reg (
    input  logic           clk,
    input  logic           rst,
    input  logic           stallM,
    input  logic           clear,
    input  logic          overflow,
    input  execute_data_t data_in,
    input  control_sign_t sign_in,
    output control_sign_t sign_out,
    output execute_data_t data_out

);

    always_ff @(posedge clk) begin
        if (!rst) begin
            data_out <= 0;
            sign_out <= 0;
        end else if (clear) begin
            data_out <= 0;
            sign_out <= 0;
        end else if (!stallM && !overflow) begin
            data_out <= data_in;
            sign_out <= sign_in;
        end else if (!stallM && overflow) begin
            data_out                 <= data_in;  //数据传递也是必须的

            sign_out.regwrite        <= 0;
            sign_out.overflow        <= 1;
            sign_out.valid           <= sign_in.valid;
            sign_out.ascii           <= sign_in.ascii;
            sign_out.instr_name      <= sign_in.instr_name;
            sign_out.exception_instr <= sign_in.exception_instr;
            sign_out.next_delayslot  <= sign_in.next_delayslot;  //如果发生溢出的指令ADD位于延迟槽，那么就需要这些信号
            sign_out.now_delayslot   <= sign_in.now_delayslot;
        end

    end
endmodule

module m_w_reg (
    input  wire           clk,
    input  wire           rst,
    input  wire           stallW,
    input  wire           clear,
    input  control_sign_t sign_in,
    output control_sign_t sign_out,
    input  memory_data_t  data_in,
    output memory_data_t  data_out

);

    always_ff @(posedge clk) begin
        if (!rst) begin
            data_out <= 0;
            sign_out <= 0;
        end else if (clear) begin
            data_out <= 0;
            sign_out <= 0;
        end else if (!stallW) begin
            data_out <= data_in;
            sign_out <= sign_in;
        end
    end
endmodule
