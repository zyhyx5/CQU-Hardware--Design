`include "define.svh"
`include "my_mips.svh"

module hilo_reg (
    input logic clk,
    input logic rst,

    //写端口
    input control_sign_t wb_sign,
    input wb_data_t      wb_data ,

    //读端口1
    output hilo_data_t hilo_data 

);
    word_t hi_reg =0, lo_reg=0 ;

    always @(posedge clk) begin
        if (!rst) begin
            hi_reg <= 0;
            lo_reg <= 0;
        end else if (wb_sign.lowrite && wb_sign.hiwrite) begin
            hi_reg <= wb_data.hi;
            lo_reg <= wb_data.lo;
        end else if (wb_sign.hiwrite) begin
            hi_reg <= wb_data.hi;
        end else if (wb_sign.lowrite) begin
            lo_reg <= wb_data.lo;
        end
    end


    always_comb begin
        
        hilo_data.hi <= hi_reg;
        hilo_data.lo <= lo_reg;

    end

endmodule
