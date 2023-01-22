module Imme_Ext(
    input [31:0] inst,
    output [31:0] imme_ext_out
);
    // OPCODE map
    parameter   LOAD = 5'b00000,
                STORE = 5'b01000,
                BRANCH = 5'b11000,
                JALR = 5'b11001,
                JAL = 5'b11011,
                OP_IMM = 5'b00100,
                OP = 5'b01100,
                AUIPC = 5'b00101,
                LUI = 5'b01101;
                
    wire [4:0] opcode = inst[6:2];
    reg [31:0] temp_out;
    
    always@(*) begin
        if(opcode == OP) begin
            // R-type
            temp_out = 32'b0;
        end
        else if(opcode == OP_IMM || opcode == LOAD || opcode == JALR) begin
            // I-type
            temp_out = {{20{inst[31]}}, inst[31:20]};
        end
        else if(opcode == STORE) begin
            // S-type
            temp_out = {{20{inst[31]}}, inst[30:25], inst[11:7]};
        end
        else if(opcode == BRANCH) begin
            // B-type
            temp_out = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
        end
        else if(opcode == LUI || opcode == AUIPC) begin
            // U-type
            temp_out = {inst[31:12], 12'b0};
        end
        else begin
            // J-type
            temp_out = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
        end
    end
    assign imme_ext_out = temp_out;
endmodule