`timescale 1ns/100ps

module branch_select(DATA1, DATA2, SELECT, MUX_OUT);

    input [31:0] DATA1, DATA2;
    input [3:0] SELECT;
    output reg MUX_OUT;

    wire BEQ, BNE, BLT, BGE, BLTU, BGEU;

    assign BEQ = DATA1 == DATA2;
    assign BNE = DATA1 != DATA2;
    assign BLT = DATA1 < DATA2;
    assign BGE = DATA1 > DATA2;
    assign BLTU = $unsigned(DATA1) < $unsigned(DATA2);
    assign BGEU = $unsigned(DATA1) > $unsigned(DATA2);
    
    
    // TODO: implement the function
    always @(*) 
    begin
        if (SELECT[3])
        #2
        begin
            case (SELECT[2:0])
                // for JAL and JALR
                3'b010:
                    MUX_OUT = 1'b1;
                // for BEQ 
                3'b000:
                    MUX_OUT = BEQ;
                // for BNE
                3'b001:
                    MUX_OUT = BNE;
                // for BLT 
                3'b100:
                    MUX_OUT = BLT;
                // for BGE 
                3'b101:
                    MUX_OUT = BGE;
                // for BLTU 
                3'b110:
                    MUX_OUT = BLTU;
                // for BGEU
                3'b111:
                    MUX_OUT = BGEU;
                default:
                    MUX_OUT = 1'b0;
            endcase
        end
        
        else 
        begin
        #2 MUX_OUT = 1'b0;
        end
    end


endmodule