`ifndef __my_mips
`define __my_mips

`include "define.svh"

// Exception
typedef enum logic [4:0] {
    CODE_INT = 5'h00,  // Interrupt
    CODE_MOD = 5'h01,  // TLB modification exception
    CODE_TLBL = 5'h02,  // TLB exception (load or instruction fetch)
    CODE_TLBS = 5'h03,  // TLB exception (store)
    CODE_ADEL = 5'h04,  // Address exception (load or instruction fetch)
    CODE_ADES = 5'h05,  // Address exception (store)
    CODE_SYS = 5'h08,  // Syscall
    CODE_BP = 5'h09,  // Breakpoint
    CODE_RI = 5'h0a,  // Reserved Instruction exception
    CODE_CPU = 5'h0b,  // CoProcesser Unusable exception
    CODE_OV = 5'h0c,  // OVerflow
    CODE_TR = 5'h0d,  // TRap
    CODE_NOP  // 没有发生异常
} exception_code_t;

// CP0 request
typedef struct packed {
    reg_addr_t  raddr;
    logic [2:0] rsel;
} cp0_rreq_t;
typedef struct packed {
    logic       we;
    reg_addr_t  waddr;
    logic [2:0] wsel;
    word_t      wdata;
} cp0_wreq_t;

// CP0 registers
//这里status的顺序不能更改，它对应了status寄存器的位置
typedef struct packed {
    logic [3:0] CU;  // [31:28]，访问协处理器单元 3 到 0。在此工作中始终为 0。
    logic RP;  // 27，精简行模式。在此工作中始终为 0。
    logic FR;  // 26，浮点寄存器模式。在此工作中始终为 0。
    logic RE;  // 25，反向字节序。在此工作中始终为 0。
    logic MX;  // 24，MDMX 和 MIPS DSP。在此工作中始终为 0。
    logic zero_0;  // 23
    logic BEV;  // 22，异常向量的位置。在此工作中始终为 1。
    logic TS;  // 21，多个 TLB 条目。在此工作中始终为 0。
    logic SR;  // 20，软复位。在此工作中始终为 0。
    logic NMI;  // 19，由 NMI 异常导致的复位。在此工作中始终为 0。
    logic ASE;  // 18，保留给 ASE。在此工作中始终为 0。
    logic [1:0] IMPL;  // [17:16]，与实现相关。在此工作中始终为 0。
    logic [7:0] IM;  // [15:8]，中断屏蔽。R/W
    logic [2:0] zero_1;  // [7:5]
    logic UM;  // 4，0：内核模式。1：用户模式。在此工作中始终为 0。
    logic R0;  // 3，保留。在此工作中始终为 0。
    logic ERL;  // 2，错误级别。在此工作中始终为 0。
    logic EXL;  // 1，异常级别。R/W
    logic IE;  // 0，中断使能。R/W
} cp0_status_t;

typedef struct packed {
    logic BD;  // 31，分支延迟槽。仅在 status.exl 为 0 时更新。R
    logic TI;  // 30，定时器中断。R
    logic [1:0] CE;     // [29:28]，协处理器不可用时的协处理器编号。在此工作中始终为 0。
    logic DC;  // 27，禁用计数寄存器。在此工作中始终为 0。
    logic PCI;  // 26，性能计数器中断。在此工作中始终为 0。
    logic [1:0] ASE_0;  // [25:24]，保留给 MCU ASE 的字段。在此工作中始终为 0。
    logic IV;           // 23，0：一般情况（0x180）；1：特殊情况（0x200）。在此工作中始终为 0。
    logic WP;  // 22，监视异常。在此工作中始终为 0。
    logic FDCI;  // 21，快速调试通道中断。在此工作中始终为 0。
    logic [2:0] zero_0;  // [20:18]
    logic [1:0] ASE_1;  // [17:16]，保留给 MCU ASE 的字段。在此工作中始终为 0。
    logic [7:0] IP;  // [15:8]，中断挂起。[7:2] R，[1:0] R/W
    logic zero_1;  // 7
    logic [4:0] exccode;  // [6:2]，异常代码。R
    logic [1:0] zero_2;  // [1:0]
} cp0_cause_t;

typedef struct packed {
    /* 
    *以下寄存器的顺序非常重要，请勿更改。
    */
    word_t desave,  // 31，EJTAG 调试异常保存寄存器
        errorepc,  // 30，最后一个错误的程序计数器
        taghi,  // 29，高位缓存标签接口
        taglo,  // 28，低位缓存标签接口
        cacheerr,  // 27，缓存奇偶校验错误控制和状态
        errctl,  // 26，奇偶校验/ECC 错误控制和状态
        perfcnt,  // 25，性能计数器接口
        depc,  // 24，最后一个 EJTAG 调试异常的程序计数器
        debug,  // 23，EJTAG 调试寄存器
        reserved22,  // 22，保留
        reserved21,  // 21，保留
        reserved20,  // 20，保留
        watchhi,  // 19，监视点控制
        watchlo,  // 18，监视点地址
        lladdr,  // 17，加载链路地址
        config_,  // 16，配置寄存器
        prid,  // 15，处理器标识和修订版本
        epc
    ;  // 14，最后一个异常的程序计数器，读/写
    cp0_cause_t cause;  // 13，最后一个常规异常的原因
    cp0_status_t status;  // 12，处理器状态和控制
    word_t compare,  // 11，定时器中断控制，读/写，通常只写
        entryhi,  // 10，TLB 条目的高位部分
        count,  // 09，处理器周期计数，读/写
        badvaddr,  // 08，报告最近地址相关异常的地址，只读
        hwrena,  // 07，启用通过 RDHWR 指令访问选定的硬件寄存器
        wired,  // 06，控制固定（"wired"）TLB 条目的数量
        pagemask,  // 05，TLB 条目中可变页大小的控制
        context_,  // 04，指向内存中页表条目的指针
        entrylo1,  // 03，奇数虚拟页的 TLB 条目的低位部分
        entrylo0,  // 02，偶数虚拟页的 TLB 条目的低位部分
        random,  // 01，随机生成的 TLB 数组索引
        index
    ;  // 00，TLB 数组的索引
} cp0_regs_t;



//用于判断异常的数据
typedef struct packed {
    cp0_cause_t  cause;   // 13，最后一个常规异常的原因
    cp0_status_t status;  // 12，处理器状态和控制
    word_t epc; // 14，最后一个异常的程序计数器，读/写
    
} cp0_exception_reg_t;  //由于cp0的寄存器过多，节选一部分进行使用
//用于判断异常的数据
typedef struct packed {
    logic ri, delayslot, exception_instr, ov;

    logic is_break, is_syscall, is_eret;
    logic adel, ades;

    word_t badvaddr;  //最近一次出错的存储器虚拟地址
    word_t epc;  //EPC返回地址寄存器中的值

    logic [7:0] interrupt_info;  //中断信号
    logic interrupt_valid;  //中断是否发生

    logic valid;  //异常是否发生
    word_t pc; //指令pc
    logic [5:0] ext_int; //硬件中断标志
} exception_sign_t;

//用于判断异常的数据
typedef struct packed {
    logic valid;  //是否发生异常
    exception_code_t code;//异常码
    logic[79:0] ascii;  //异常信息
} exception_data_t;



typedef enum logic [4:0] {
    LOGIC_,
    SHIFT_,
    NOP_,
    STORE_,
    MOVE_,
    ARITHMETIC_,
    MUL_,
    JAL_,
    LOAD_
} instr_class_t;

typedef enum logic [8:0] {
    ALU_ADDU,
    ALU_AND,
    ALU_OR,
    ALU_ADD,
    ALU_SLL,
    ALU_SRL,
    ALU_SRA,
    ALU_SUB,
    ALU_SLT,
    ALU_NOR,
    ALU_XOR,
    ALU_SUBU,
    ALU_SLTU,
    ALU_PASSA,
    ALU_LUI,
    ALU_PASSB,
    ALU_MUL,
    ALU_MULU,
    ALU_CLZ,
    ALU_CLO,
    sync
} alufunc_t;

typedef enum logic [6:0] {

    NOP,
    ADDI,
    ADDIU,
    SLTI,
    SLTIU,
    ANDI,
    ORI,
    XORI,
    ADDU,
    RESERVED,
    BEQ,
    BNE,
    BGEZ,
    BGTZ,
    BLEZ,
    BLTZ,
    BGEZAL,
    BLTZAL,
    J,
    JAL,
    LB,
    LBU,
    LH,
    LHU,
    LW,
    LWL,
    LWR,
    SB,
    SH,
    SW,
    SWL,
    SWR,
    ERET,
    MFC0,
    MTC0,
    ADD,
    SUB,
    SUBU,
    SLT,
    SLTU,
    DIV,
    DIVU,
    MULT,
    MULTU,
    AND,
    NOR,
    OR,
    XOR,
    SLLV,
    SLL,
    SRAV,
    SRA,
    SRLV,
    SRL,
    SYNC,
    JR,
    JALR,
    MFHI,
    MFLO,
    MTHI,
    MTLO,
    MOVN,
    MOVZ,
    BREAK,
    SYSCALL,
    PREF,
    CLZ,
    CLO,
    MUL,
    MADD,
    MADDU,
    MSUB,
    MSUBU,
    LUI
} inst_name_t;

//---------------------------控制信号--------------
//------------------------------------------------
typedef struct packed {
    alufunc_t alufunc;
    logic regwrite;
    logic memtoreg;
    logic [3:0] wen;

    logic         reg1_read;
    logic         reg2_read;
    instr_class_t instr_class;
    inst_name_t   instr_name;

    logic [1:0] exe_cnt_0;

    logic [39:0] ascii; //显示指令

    //除法指令
    logic start_div;
    logic annul_div;
    logic ready_div;
    logic is_signed;  //是有符号数除法还是无符号数除法

    //hilo指令
    logic hiwrite, lowrite;
    logic hitoreg, lotoreg;

    //mfc0,mtc0指令
    cp0_rreq_t cp0_rreq;
    cp0_wreq_t cp0_wreq;

    //分支指令
    word_t link_addr;  //返回地址
    word_t branch_target_address;  //跳转目标地址
    logic branch_flag;  //是否跳转
    
    logic next_delayslot;  //下一条指令是延迟指令；
    logic now_delayslot;

    //LOAD指令写地址
    word_t mem_addr;  //sw类型指令写地址

    //异常信号
    logic overflow;  //溢出标志
    logic valid;     //指令是否有效
    logic exception_instr; //异常指令信号，表示取指地址不对齐
    logic [5:0] ext_int;

} control_sign_t;

typedef struct packed {
    word_t imm;
    reg_addr_t writereg;

} control_data_t;

typedef struct packed {
    logic  inst_sram_en;
    wen_t  inst_sram_wen;
    word_t inst_sram_addr;
    word_t inst_sram_wdata;
    word_t inst_sram_rdata;
} inst_sram_t;


typedef struct packed {
    logic  data_sram_en;
    wen_t  data_sram_wen;
    word_t data_sram_addr;
    word_t data_sram_wdata;
    word_t data_sram_rdata;
} data_sram_t;

typedef struct packed {
    word_t     debug_wb_pc;
    wen_t      debug_wb_rf_wen;
    reg_addr_t debug_wb_rf_wnum;
    word_t     debug_wb_rf_wdata;
} debug_wb_t;





//---------------------------五个阶段数据----------
//------------------------------------------------

//代表从fetch阶段传递给decode阶段的instrF和pc_plus4
typedef struct packed {
    word_t instr;
    word_t pc_plus4;
    word_t pc;
    logic[5:0] ext_int;
} fetch_data_t;



typedef struct packed {
    word_t     RD1_data,    RD2_data;
    word_t     imm;
    reg_addr_t rs_addr,     rt_addr,  rd_addr;
    word_t     pc_branch;
    word_t     pc;
    logic      zero;
    word_t     instr;
    word_t     signimm_sl2;
    reg_addr_t writereg;
    logic[5:0] ext_int;

} decode_data_t;

typedef struct packed {
    //execute阶段产生的信号，用来给控制信号赋值。
    logic overflow;
    logic regwrite;

    word_t     aluout;
    word_t     writedata;
    reg_addr_t writereg;
    reg_addr_t rs_addr,   rt_addr,  rd_addr;
    word_t     imm;
    word_t     instr;
    word_t     pc;
    word_t     RD1_data,  RD2_data;
    word_t     srca,      srcb;
    word_t     hi,        lo;
    logic[5:0] ext_int;

    cp0_wreq_t cp0_wreq;

} execute_data_t;

typedef struct packed {
    word_t     aluout;
    word_t     writedata;            //向数据存储器中写入的数据
    reg_addr_t writereg;             //写入寄存器的寄存器地址
    word_t     readdata;             //从数据寄存器中读出的数据
    word_t     instr;
    word_t     pc;
    word_t     result;
    word_t     hi,        lo;
    word_t     RD1_data,  RD2_data;
    logic[5:0] ext_int;

    cp0_wreq_t cp0_wreq;


} memory_data_t;

typedef struct packed {

    reg_addr_t writereg;
    // word_t     writedata;
    word_t     instr;
    word_t     pc;
    word_t     result;
    word_t     hi,       lo;
    logic[5:0] ext_int;

    cp0_wreq_t cp0_wreq;

} wb_data_t;

typedef struct packed {
    word_t hi;
    word_t lo;
} hilo_data_t;


//---------------------与sram进行交互的数据--------
//代表从fetch阶段给inst_sram的pc地址
typedef struct packed {word_t pc;} fetch_data_out_t;

//代表从memory阶段给data_sram的aluout地址
typedef struct packed {
    word_t mem_addr;
    word_t writedata;
    logic [3:0] wen;
} memory_data_out_t;
//代表从write_back阶段送出的debug数据
typedef struct packed {
    word_t pc;
    word_t result;
    word_t writereg;
    logic [3:0] regwrite;

} wb_data_out_t;
//从inst_sram得到的数据
typedef struct packed {
    word_t instr;
    logic [5:0] ext_int;
    //硬件中断信息，此处是偷懒的写法
} inst_sram_data_t;
//从inst_sram得到的数据
typedef struct packed {word_t readdata;} data_sram_data_t;



typedef struct packed {
    logic forwardAD, forwardBD;
    logic [1:0] forwardAE, forwardBE;
    logic stallF, stallD, flushE;
} hazard_sign_t;


typedef struct packed {
    logic stall_reqPC, stall_reqF, stall_reqD;
    logic stall_reqE, stall_reqW;
    logic stall_reqE_div;
    logic stall_reqD_load;

} stall_req_sign_t;

typedef struct packed {
    logic stallPC, stallF, stallD;
    logic stallE, stallM, stallW;
    logic stallPC_1;
} stall_sign_t;

typedef struct packed {
    logic flushPC, flushF, flushD;
    logic flushE,  flushM, flushW;
} flush_sign_t;

`endif

