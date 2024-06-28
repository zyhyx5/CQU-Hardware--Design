`include "my_mips.svh"
`include "define.svh"
`ifndef my_interface
`define my_interface


interface f_d_reg_intf(input word_t instrF,input word_t pc_plus4F);

    word_t instrD;
    word_t pc_plusD;

    modport data_in (
        input instrF,
        input pc_plus4F
    );
    modport data_out (
        output instrD,
        output pc_plusD
    );

endinterface //f_d_reg



`endif