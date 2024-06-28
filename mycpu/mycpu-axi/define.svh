`ifndef __define
`define __define


//信号长度
typedef logic [31:0] word_t;
typedef logic [63:0] double_word_t;
typedef logic [4:0] reg_addr_t;
typedef logic [3:0] wen_t;  //写使能信号（write_enable)]

//指令种类
`define LOGIC 4'b0010
`define SHIFT 4'b0100
`define NOP 4'b0000
`define STORE 4'b1010
`define MOVE 4'b0110
`define ARITHMETIC 4'b1000
`define MUL 4'b1001
`define JAL 4'b1011


//逻辑运算func编码
`define FUNC_AND 6'b100100
`define FUNC_OR 6'b100101
`define FUNC_XOR 6'b100110
`define FUNC_NOR 6'b100111 

`define OP_ANDI 6'b001100
`define OP_ORI 6'b001101
`define OP_XORI 6'b001110
`define OP_LUI 6'b001111

//移位指令func编码
`define FUNC_SLL 6'b000000
`define FUNC_SLLV 6'b000100
`define FUNC_SRA 6'b000011
`define FUNC_SRAV 6'b000111
`define FUNC_SRL 6'b000010
`define FUNC_SRLV 6'b000110

//sync,pref指令
`define FUNC_SYNC 6'b001111   //sync指令：保证加载存储操作顺序
`define OP_PREF 6'b110011     //pref指令：缓存预取


//移动指令编码
`define FUNC_MOVZ 6'b001010
`define FUNC_MOVN 6'b001011
`define FUNC_MFHI 6'b010000
`define FUNC_MTHI 6'b010001
`define FUNC_MFLO 6'b010010 
`define FUNC_MTLO 6'b010011

//简单运算指令编码
`define FUNC_SLT 6'b101010
`define FUNC_SLTU 6'b101011  
`define FUNC_ADD 6'b100000
`define FUNC_ADDU 6'b100001
`define FUNC_SUB 6'b100010
`define FUNC_SUBU 6'b100011
`define FUNC_ADDIU 6'b001001
`define FUNC_CLZ 6'b100000
`define FUNC_CLO 6'b100001
`define OP_SLTI 6'b001010
`define OP_ADDI 6'b001000
`define OP_SLTIU 6'b001011 
`define OP_ADDIU 6'b001001

`define FUNC_MULT 6'b011000
`define FUNC_MULTU 6'b011001
`define FUNC_MUL 6'b000010
`define FUNC_MADD 6'b000000
`define FUNC_MADDU 6'b000001
`define FUNC_MSUB 6'b000100
`define FUNC_MSUBU 6'b000101
`define FUNC_DIV 6'b011010
`define FUNC_DIVU 6'b011011

//分支指令
`define FUNC_JALR 6'b001001
`define FUNC_JR 6'b001000

`define OP_J 6'b000010
`define OP_JAL 6'b000011
`define OP_BEQ 6'b000100
`define OP_BGTZ 6'b000111
`define OP_BNE 6'b000101
`define OP_BLEZ 6'b000110

`define RT_BGEZ 5'b00001
`define RT_BGEZAL 5'b10001
`define RT_BLTZ 5'b00000
`define RT_BLTZAL 5'b10000
//访存指令

`define OP_LB 6'b100000
`define OP_LBU 6'b100100
`define OP_LH 6'b100001
`define OP_LHU 6'b100101
`define OP_LW 6'b100011
`define OP_LWL 6'b100010
`define OP_LWR 6'b100110

`define OP_LL 6'b110000

`define OP_SB 6'b101000
`define OP_SC 6'b111000
`define OP_SH 6'b101001
`define OP_SW 6'b101011
`define OP_SWL 6'b101010
`define OP_SWR 6'b101110

//异常中断相关指令
`define OP_ERET 6'b010000
`define C_ERET 5'b10000
`define C_MFC0 5'b00000
`define C_MTC0 5'b00100

`define FUNC_SYSCALL 6'b001100
`define FUNC_BREAK 6'b001101

//异常中的自陷指令
`define FUNC_TEQ 6'b110100
`define FUNC_TEQI 5'b01100
`define FUNC_TGE 6'b110000
`define FUNC_TGEI 5'b01000
`define FUNC_TGEIU 5'b01001
`define FUNC_TGEU 6'b110001
`define FUNC_TLT 6'b110010
`define FUNC_TLTI 5'b01010
`define FUNC_TLTIU 5'b01011
`define FUNC_TLTU 6'b110011
`define FUNC_TNE 6'b110110
`define FUNC_TNEI 5'b01110


`define EXE_NOP 6'b000000
`define SSNOP 32'b00000000000000000000000001000000


`define R1_INST 6'b000000            //R1型指令指令码   
`define R2_INST 6'b011100            //R2型指令指令码   
`define REGIMM_INST 6'b000001     //立即数指令

//cp0寄存器

`define BADVADDR 5'd8 
`define COUNT 5'd9  
`define COMPARE 5'd11
`define STATUS 5'd12
`define CAUSE 5'd13
`define EPC 5'd14

//cp0寄存器初试状态定义
`define CP0_INIT {                                      \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0000_0000_0100_0000_0000_0000_0000_0000,        \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0,                                              \
    32'b0                                               \
};


`endif


