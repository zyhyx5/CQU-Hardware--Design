`include "my_mips.svh"
`include "define.svh"

module div (

    input logic clk,
    input logic rst,

    input logic  is_signed,
    input word_t opdata1,
    input word_t opdata2,
    input logic  start_div,
    input logic  annul_div,

    output double_word_t result,
    output logic      ready
);

    logic                                       [32:0] div_temp;
    logic                                       [ 5:0] cnt = 0;
    logic[64:0]                                                dividend;
    word_t                                             divisor;
    word_t                                             temp_op1;
    word_t                                             temp_op2;

    enum logic[2:0] {DivFree, DivByZero, DivOn, DivEnd}        state = DivFree;
    assign div_temp = {1'b0, dividend[63:32]} - {1'b0, divisor};

    logic [6:0] x;

    always @(posedge clk) begin
        if (!rst) begin
            state  <= DivFree;
            ready  <= 0;
            result <= 0;
        end else begin
            case (state)
                DivFree: begin  //DivFree状态
                    ready <= 0;

                    if (start_div == 1'b1 && annul_div == 1'b0) begin
                        if (opdata2 == 0) begin
                            state <= DivByZero;
                        end else begin
                            state <= DivOn;
                            cnt   <= 6'b000000;

                            if (is_signed == 1'b1 && opdata1[31] == 1'b1) begin
                                temp_op1 = ~opdata1 + 1;
                                x = 7'd10;
                            end else begin
                                temp_op1 = opdata1;

                            end

                            if (is_signed == 1'b1 && opdata2[31] == 1'b1) begin
                                temp_op2 = ~opdata2 + 1;
                            end else begin
                                temp_op2 = opdata2;
                            end
                            dividend <= 0;
                            dividend[32:1] <= temp_op1;
                            divisor <= temp_op2;
                        end
                    end else begin
                        ready  <= 0;
                        result <= 0;
                    end
                end
                DivByZero: begin  //DivByZero状态
                    dividend <= 0;
                    state <= DivEnd;
                end
                DivOn: begin  //DivOn状态
                    if (annul_div == 1'b0) begin
                        if (cnt != 6'b100000) begin
                            if (div_temp[32] == 1'b1) begin  //减完结果为负数
                                dividend <= {dividend[63:0], 1'b0};  //div_temp左移一位
                            end else begin
                                dividend <= {div_temp[31:0], dividend[31:0], 1'b1};
                            end
                            cnt <= cnt + 1;

                        end else begin
                            if ((is_signed == 1'b1) && ((opdata1[31] ^ opdata2[31]))) begin
                                dividend[31:0] <= (~dividend[31:0] + 1);
                            end
                            if ((is_signed == 1'b1) && ((opdata1[31] ^ dividend[64]))) begin
                                dividend[64:33] <= (~dividend[64:33] + 1);
                            end
                            state <= DivEnd;
                            cnt   <= 6'b000000;


                        end
                    end else begin
                        state <= DivFree;
                    end
                end
                DivEnd: begin  //DivEnd状态
                    result <= {dividend[64:33], dividend[31:0]};
                    ready  <= 1'b1;
                    state  <= DivFree;

                    if (start_div == 0) begin
                        state  <= DivFree;
                        ready  <= 0;
                        result <= 0;
                    end
                end
            endcase
        end
    end
endmodule
