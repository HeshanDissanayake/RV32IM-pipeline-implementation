`timescale 1ns/100ps

// including the modules
`include "control_unit.v"
`include "alu.v"
`include "reg_file.v"
// `include "data_cache_memory.v"
// `include "ins_cache_memory.v"
`include "immediate_select.v"
`include "branch_select.v"
`include "mux2to1_32bit.v"
`include "mux4to1_32bit.v"

module cpu(PC, INSTRUCTION, CLK, RESET, memReadEn, memWriteEn, DATA_CACHE_ADDR, DATA_CACHE_DATA, DATA_CACHE_READ_DATA, DATA_CACHE_BUSY_WAIT,
            insReadEn, INS_CACHE_BUSY_WAIT);

    input [31:0] INSTRUCTION; //fetched INSTRUCTIONtructions
    input CLK, RESET; // clock and reset for the cpu
    input DATA_CACHE_BUSY_WAIT; // busy wait signal from the memory
    input INS_CACHE_BUSY_WAIT; // busy wait from the instruction memory
    input [31:0] DATA_CACHE_READ_DATA; // input from the memory read
    output reg [31:0] PC; //programme counter
    output [3:0] memReadEn; // control signal to the data memory
    output [2:0] memWriteEn; // control signal to the data memory
    output reg insReadEn; // read enable for the instruction read
    output [31:0] DATA_CACHE_ADDR, DATA_CACHE_DATA; // output signal to the memory (address and the write data input)

//************************** STAGE 1 **************************
    // data lines
    reg [31:0] PR_INSTRUCTION, PR_PC_S1;

    // structure
        // additional wires
        wire [31:0] PC_PLUS_4, PC_NEXT;

        // units
        // TODO: ALU out should be defined later, Branch select out should be defined later
        mux2to1_32bit muxjump (PC_PLUS_4, ALU_OUT, PC_NEXT, BRANCH_SELECT_OUT);

        // connections
        assign PC_PLUS_4 = PC + 4;
    

//************************** STAGE 2 **************************
    // data lines
    reg [31:0] PR_PC_S2, PR_DATA_1_S2, PR_DATA_2_S2, PR_IMMEDIATE_SELECT_OUT;
    reg [4:0] PR_REGISTER_WRITE_ADDR_S2;

    // control lines
    reg [3:0] PR_BRANCH_SELECT_S2, PR_MEM_READ_S2;
    reg [4:0] PR_ALU_SELECT;
    reg PR_OPERAND1_SEL, PR_OPERAND2_SEL;
    reg [2:0] PR_MEM_WRITE_S2; 
    reg [1:0] PR_REG_WRITE_SELECT_S2;
    reg PR_REG_WRITE_EN_S2; 

    // structure
        // additionl wires
        wire [31:0] DATA1_S2, DATA2_S2, IMMEDIATE_OUT_S2; 
        wire [3:0] IMMEDIATE_SELECT;
        wire [3:0] BRANCH_SELECT, MEM_READ_S2;
        wire [4:0] ALU_SELECT;
        wire OPERAND1_SEL, OPERAND2_SEL;
        wire [2:0] MEM_WRITE_S2; 
        wire [1:0] REG_WRITE_SELECT_S2;
        wire REG_WRITE_EN_S2; 

        // units
        //TODO: WRITE_DATA, WRITE_ADDR, WRITE_EN 
        reg_file myreg (REG_WRITE_DATA, 
                        DATA1_S2, 
                        DATA2_S2, 
                        PR_REGISTER_WRITE_ADDR_S4, 
                        PR_INSTRUCTION[19:15], 
                        PR_INSTRUCTION[24:20], 
                        PR_REG_WRITE_EN_S4, 
                        CLK, 
                        RESET); //alu module

        immediate_select myImmediate (PR_INSTRUCTION, IMMEDIATE_SELECT, IMMEDIATE_OUT_S2);
        
        control_unit myControl (PR_INSTRUCTION, 
                                ALU_SELECT, 
                                REG_WRITE_EN_S2, 
                                MEM_WRITE_S2, 
                                MEM_READ_S2, 
                                BRANCH_SELECT, 
                                IMMEDIATE_SELECT, 
                                OPERAND1_SEL, 
                                OPERAND2_SEL, 
                                REG_WRITE_SELECT_S2, 
                                RESET);


    
//************************** STAGE 3 **************************
    // data lines
    reg [31:0] PR_PC_S3, PR_ALU_OUT_S3, PR_DATA_2_S3;
    reg [4:0] PR_REGISTER_WRITE_ADDR_S3;

    // control lines
    reg [3:0] PR_MEM_READ_S3;
    reg [2:0] PR_MEM_WRITE_S3; 
    reg [1:0] PR_REG_WRITE_SELECT_S3;
    reg PR_REG_WRITE_EN_S3; 

    // structure
        // additional wires
        wire[31:0] ALU_IN_1, ALU_IN_2;
        wire[31:0] ALU_OUT;
        wire BRANCH_SELECT_OUT;

        // units
        mux2to1_32bit oparand1_mux (PR_DATA_1_S2, PR_PC_S2, ALU_IN_1, PR_OPERAND1_SEL);
        mux2to1_32bit oparand2_mux (PR_DATA_2_S2, PR_IMMEDIATE_SELECT_OUT, ALU_IN_2, PR_OPERAND2_SEL);
        alu myAlu (ALU_IN_1, ALU_IN_2, ALU_OUT, PR_ALU_SELECT);
        branch_select myBranchSelect(PR_DATA_1_S2, PR_DATA_2_S2, PR_BRANCH_SELECT_S2, BRANCH_SELECT_OUT);

//************************** STAGE 4 **************************
    // data lines
    reg [31:0] PR_PC_S4, PR_ALU_OUT_S4, PR_DATA_CACHE_OUT;
    reg [4:0] PR_REGISTER_WRITE_ADDR_S4;

    // control lines
    reg [1:0] PR_REG_WRITE_SELECT_S4;
    reg PR_REG_WRITE_EN_S4; 

    // structure
        // additional wires
        wire [31:0] PC_PLUS_4_2;

        // units
        

        assign DATA_CACHE_DATA = PR_DATA_2_S3;
        assign DATA_CACHE_ADDR = PR_ALU_OUT_S3;
        assign memWriteEn = PR_MEM_WRITE_S3;
        assign memReadEn = PR_MEM_READ_S3;
    
//************************** STAGE 5 **************************
    // structure
        // additional wires
        wire [31:0] REG_WRITE_DATA;

        // units
        // mux4to1_32bit regWriteSelMUX (PR_PC_S4, PR_ALU_OUT_S4, PR_DATA_CACHE_OUT, 32'b0, REG_WRITE_DATA, PR_REG_WRITE_SELECT_S4);
        mux4to1_32bit regWriteSelMUX (PR_DATA_CACHE_OUT, PR_ALU_OUT_S4, 32'b0, PR_PC_S4, REG_WRITE_DATA, PR_REG_WRITE_SELECT_S4);

        // connections

// register updating section
always @(posedge CLK) begin
    #0.02
    if (!(DATA_CACHE_BUSY_WAIT || INS_CACHE_BUSY_WAIT))
    begin
        //************************** STAGE 4 **************************
        PR_REGISTER_WRITE_ADDR_S4 = PR_REGISTER_WRITE_ADDR_S3;
        PR_PC_S4 = PR_PC_S3;
        
        PR_REG_WRITE_SELECT_S4  = PR_REG_WRITE_SELECT_S3;
        PR_REG_WRITE_EN_S4 = PR_REG_WRITE_EN_S3;

        PR_ALU_OUT_S4 = PR_ALU_OUT_S3;
        PR_DATA_CACHE_OUT = DATA_CACHE_READ_DATA;
        
        //************************** STAGE 3 **************************
        #0.001
        PR_REGISTER_WRITE_ADDR_S3 = PR_REGISTER_WRITE_ADDR_S2;
        PR_PC_S3 = PR_PC_S2;
        PR_ALU_OUT_S3 = ALU_OUT;
        PR_DATA_2_S3 = PR_DATA_2_S2;    
        
        PR_MEM_READ_S3 = PR_MEM_READ_S2;
        PR_MEM_WRITE_S3 = PR_MEM_WRITE_S2;
        PR_REG_WRITE_SELECT_S3  = PR_REG_WRITE_SELECT_S2;
        PR_REG_WRITE_EN_S3 = PR_REG_WRITE_EN_S2;

        //************************** STAGE 2 **************************  
        #0.001  
        PR_REGISTER_WRITE_ADDR_S2 = PR_INSTRUCTION[11:7]; // TODO: check the 11:7 value
        PR_PC_S2 = PR_PC_S1;
        PR_DATA_1_S2 = DATA1_S2;
        PR_DATA_2_S2 = DATA2_S2;
        PR_IMMEDIATE_SELECT_OUT = IMMEDIATE_OUT_S2;

        PR_BRANCH_SELECT_S2 =  BRANCH_SELECT;
        PR_ALU_SELECT =  ALU_SELECT;
        PR_OPERAND1_SEL =  OPERAND1_SEL;
        PR_OPERAND2_SEL =  OPERAND2_SEL;
        PR_MEM_READ_S2 =  MEM_READ_S2;
        PR_MEM_WRITE_S2  =  MEM_WRITE_S2;
        PR_REG_WRITE_SELECT_S2 = REG_WRITE_SELECT_S2;
        PR_REG_WRITE_EN_S2 = REG_WRITE_EN_S2; 

        //************************** STAGE 1 **************************
        #0.001
        PR_INSTRUCTION = INSTRUCTION;
        PR_PC_S1 = PC_PLUS_4;
    end

end

// PC update with the clock edge
always @ (posedge CLK) begin     
    if (RESET == 1'b1) 
        begin
            PC = -4; // reset the pc counter
            // clearing the pipeline registers
            PR_INSTRUCTION = 32'b0;
            PR_PC_S1 = 32'b0;

            PR_PC_S2 = 32'b0;
            PR_DATA_1_S2 = 32'b0; 
            PR_DATA_2_S2 = 32'b0; 
            PR_IMMEDIATE_SELECT_OUT = 32'b0;
            
            PR_REGISTER_WRITE_ADDR_S2 = 5'b0;
            PR_BRANCH_SELECT_S2 = 4'b0; 
            PR_MEM_READ_S2 = 4'b0;
            PR_ALU_SELECT = 5'b0;
            PR_OPERAND1_SEL = 1'b0;
            PR_OPERAND2_SEL = 1'b0;
            PR_MEM_WRITE_S2 = 3'b0; 
            PR_REG_WRITE_SELECT_S2 = 2'b0;
            PR_REG_WRITE_EN_S2 = 1'b0; 

            PR_PC_S3 = 32'b0; 
            PR_ALU_OUT_S3 = 32'b0;
            PR_DATA_2_S3 = 32'b0;
            PR_REGISTER_WRITE_ADDR_S3 = 5'b0;
            PR_MEM_READ_S3 = 4'b0;
            PR_MEM_WRITE_S3 = 3'b0; 
            PR_REG_WRITE_SELECT_S3 = 2'b0;
            PR_REG_WRITE_EN_S3 = 1'b0; 

            PR_PC_S4 = 32'b0;
            PR_ALU_OUT_S4 = 32'b0;
            PR_DATA_CACHE_OUT = 32'b0;
            PR_REGISTER_WRITE_ADDR_S4 = 5'b0;
            PR_REG_WRITE_SELECT_S4 = 2'b0;
            PR_REG_WRITE_EN_S4 = 1'b0;

            insReadEn = 1'b0; // disable the read enable signal of the instruction memory
        end
    else 
    begin
        insReadEn = 1'b0;
        #1
        if (!(DATA_CACHE_BUSY_WAIT || INS_CACHE_BUSY_WAIT)) 
        begin 
            PC = PC_NEXT;       // increment the pc
            insReadEn = 1'b1; // enable read from the instruction memory
        end
    end
end

endmodule