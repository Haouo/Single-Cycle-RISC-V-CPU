module Controller(
    // inputs
    input [4:0] opcode,
    input [2:0] func3,
    input func7,
    input BrEq,
    input BrLT,
    // outputs
    // write-back control
    output [1:0] wb_sel,
    output wb_en,
    // branch or jump control
    output next_pc_sel,
    output BrUn,
    // alu control
    output [3:0] alu_op,
    output alu_op1_sel,
    output alu_op2_sel,
    // IM and DM control
    output [3:0] im_w_en,
    output [3:0] dm_w_en,
    // for Lui inst.
    output isLui
);
    // define ALU OP map
    parameter   ADD = 4'd0,
                SLL = 4'd1,
                SLT = 4'd2,
                SLTU = 4'd3,
                XOR = 4'd4,
                SRL = 4'd5,
                OR = 4'd6,
                AND = 4'd7,
                SUB = 4'd8,
                SRA = 4'd13;

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
    
    // func3 map for branch inst.
    parameter   EQ = 3'b000,
                NE = 3'b001,
                LT = 3'b100,
                GE = 3'b101,
                LTU = 3'b110,
                GEU = 3'b111;

    // write-back enable and select
    assign wb_en = (opcode == STORE || opcode == BRANCH) ? 1'b0 : 1'b1;

    reg [1:0] temp_wb_sel;
    assign wb_sel = temp_wb_sel;
    always @(*) begin
        if(opcode == JAL || opcode == JALR)
            temp_wb_sel = 2'd2; // chose PC + 4
        else if(opcode == LOAD)
            temp_wb_sel = 2'd1; // chose ld_data_f
        else
            temp_wb_sel = 2'd0; // chosel alu_out
    end

    // alu_op1_sel and alu_op2_sel
    reg temp_op1_sel;
    always@(*) begin
        if(opcode == JAL || opcode == BRANCH || opcode == AUIPC)
            temp_op1_sel = 1'b1; // chose PC
        else
            temp_op1_sel = 1'b0; // chose rs1
    end
    assign alu_op1_sel = temp_op1_sel;
    assign alu_op2_sel = (opcode == OP) ? 1'b0 : 1'b1; // 1 for imm, 0 for rs2

    // alu_op
    reg [3:0] temp_alu_op;
    assign alu_op = temp_alu_op;
    always @(*) begin
        if(opcode == OP) begin
            if(func7 == 1'b0) begin
                case(func3)
                    3'b000: temp_alu_op = ADD;
                    3'b001: temp_alu_op = SLL;
                    3'b010: temp_alu_op = SLT;
                    3'b011: temp_alu_op = SLTU;
                    3'b100: temp_alu_op = XOR;
                    3'b101: temp_alu_op = SRL;
                    3'b110: temp_alu_op = OR;
                    3'b111: temp_alu_op = AND;
                endcase
            end
            else begin
                temp_alu_op = (func3 == 3'b000) ? SUB : SRA;
            end
        end
        else if(opcode == OP_IMM) begin
            case(func3)
                3'b000: temp_alu_op = ADD;
                3'b001: temp_alu_op = SLL;
                3'b010: temp_alu_op = SLT;
                3'b011: temp_alu_op = SLTU;
                3'b100: temp_alu_op = XOR;
                3'b101: begin
                    if(func7 == 1'b0)
                        temp_alu_op = SRL;
                    else
                        temp_alu_op = SRA;
                end
                3'b110: temp_alu_op = OR;
                3'b111: temp_alu_op = AND;
                default: temp_alu_op = ADD;
            endcase
        end
        else begin
            // LOAD, STORE, LUI, AUIPC, JAL, JALR, BRANCH
            temp_alu_op = ADD;
        end
    end

    // BrUn
    assign BrUn = (func3 == LTU || func3 == GEU) ? 1'b1 : 1'b0;

    // next_pc_sel
    reg temp_next_pc_sel;
    assign next_pc_sel = temp_next_pc_sel;
    always @(*) begin
        if(opcode == JAL || opcode == JALR) begin
            temp_next_pc_sel = 1'b1; // always jump
        end
        else if(opcode == BRANCH) begin
            case(func3)
                EQ: temp_next_pc_sel = BrEq;
                NE: temp_next_pc_sel = ~BrEq;
                LT: temp_next_pc_sel = BrLT;
                GE: temp_next_pc_sel = ~BrLT;
                LTU: temp_next_pc_sel = BrLT;
                GEU: temp_next_pc_sel = ~BrLT;
            endcase
        end
        else begin
            temp_next_pc_sel = 1'b0; // PC + 4
        end
    end

    // im_w_en
    assign im_w_en = 4'b0000; // do not write new data into inst. mem
    // dm_w_en
    reg [3:0] temp_dm_w_en;
    assign dm_w_en = temp_dm_w_en;
    always@(*) begin
        if(opcode == STORE) begin
            case(func3)
                3'b010: temp_dm_w_en = 4'b1111; // SW
                3'b001: temp_dm_w_en = 4'b0011; // SH
                3'b000: temp_dm_w_en = 4'b0001; // SB
            endcase
        end
        else begin
            temp_dm_w_en = 4'b0000;
        end
    end

    // for Lui inst.
    assign isLui = (opcode == LUI) ? 1'b1 : 1'b0;
endmodule