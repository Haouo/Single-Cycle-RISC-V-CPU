// include all components
`include "./src/SRAM.v"
`include "./src/RegFile.v"
`include "./src/Reg_PC.v"
`include "./src/LD_Filter.v"
`include "./src/Imme_Ext.v"
`include "./src/Decoder.v"
`include "./src/Controller.v"
`include "./src/ALU.v"
`include "./src/BranchComp.v"


// top module of Single-Cycle RISC-V CPU
module Top(
    input clk,
    input rst
);
    // datapath signals
    wire [4:0] opcode;
    wire [2:0] func3;
    wire func7;
    wire [31:0] inst, pc, pc_plus_4, next_pc;
    wire [4:0] rs1_index, rs2_index, rd_index;
    wire [31:0] rs1_data_or_zero, rs1_data, rs2_data, ld_data, ld_data_f, wb_data;
    wire [31:0] sext_imme, alu_out, alu_op1, alu_op2;
    // control signals
    wire    next_pc_sel,
            wb_en,
            alu_op1_sel,
            alu_op2_sel,
            BrUn,
            BrEq,
            BrLT,
            isLui;
    wire [1:0] wb_sel;
    wire [3:0]  alu_op,
                im_w_en,
                dm_w_en;
    
    // module declaration
    SRAM im(
        .clk(clk),
        .w_en(im_w_en),
        .address(pc[15:0]),
        .write_data(32'd0),
        .read_data(inst)
    );

    SRAM dm(
        .clk(clk),
        .w_en(dm_w_en),
        .address(alu_out[15:0]),
        .write_data(rs2_data),
        .read_data(ld_data) 
    );

    Decoder decoder(
        .inst(inst),
        .dc_out_func3(func3),
        .dc_out_func7(func7),
        .dc_out_opcode(opcode),
        .dc_out_rs1_index(rs1_index),
        .dc_out_rs2_index(rs2_index),
        .dc_out_rd_index(rd_index)
    );

    Imme_Ext imme_ext(
        .inst(inst),
        .imme_ext_out(sext_imme)
    );
    
    RegFile regfile(
        .clk(clk),
        .wb_en(wb_en),
        .wb_data(wb_data),
        .rs1_index(rs1_index),
        .rs2_index(rs2_index),
        .rd_index(rd_index),
        .rs1_out_data(rs1_data),
        .rs2_out_data(rs2_data)
    );

    assign rs1_data_or_zero = (isLui == 1'b1) ? 32'd0 : rs1_data;
    assign alu_op1 = (alu_op1_sel == 1'b1) ? pc : rs1_data_or_zero;
    assign alu_op2 = (alu_op2_sel == 1'b1) ? sext_imme : rs2_data;
    ALU alu(
        .alu_op(alu_op),
        .operand1(alu_op1),
        .operand2(alu_op2),
        .alu_out(alu_out)
    );

    assign pc_plus_4 = pc + 32'd4;
    assign next_pc = (next_pc_sel == 1'b1) ? (alu_out & (~32'd1)) : (pc_plus_4);
    Reg_PC reg_pc(  
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc),
        .current_pc(pc)
    );

    BranchComp branch_comp(
        .operand1(rs1_data),
        .operand2(rs2_data),
        .BrUn(BrUn),
        .BrEq(BrEq),
        .BrLT(BrLT)
    );

    LD_Filter lf_filter(
        .func3(func3),
        .in_data(ld_data),
        .out_data(ld_data_f)
    );

    reg [31:0] temp_wb_data;
    assign wb_data = temp_wb_data;
    always @(*) begin
        if(wb_sel == 2'd0)
            temp_wb_data = alu_out;
        else if(wb_sel == 2'd1)
            temp_wb_data = ld_data_f;
        else
            temp_wb_data = pc_plus_4; // for JAL and JALR
    end

    Controller controller(
        .opcode(opcode),
        .func3(func3),
        .func7(func7),
        .BrEq(BrEq),
        .BrLT(BrLT),
        .BrUn(BrUn),
        .next_pc_sel(next_pc_sel),
        .wb_sel(wb_sel),
        .wb_en(wb_en),
        .im_w_en(im_w_en),
        .dm_w_en(dm_w_en) ,
        .alu_op(alu_op),
        .alu_op1_sel(alu_op1_sel),
        .alu_op2_sel(alu_op2_sel),
        .isLui(isLui)
    );
endmodule