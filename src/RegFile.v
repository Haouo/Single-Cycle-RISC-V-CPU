module RegFile(
    input clk,
    input wb_en,
    input [31:0] wb_data,
    input [4:0] rd_index,
    input [4:0] rs1_index,
    input [4:0] rs2_index,
    output [31:0] rs1_out_data,
    output [31:0] rs2_out_data
);
    reg [31:0] regFile[31:0]; // register array
    assign regFile[0] = 32'd0; // register x0 is always zero

    // main part
    always@ (posedge clk) begin
        if(wb_en == 1 && rd_index != 5'd0)
            regFile[rd_index] <= wb_data;
    end

    // assign output value
    assign rs1_out_data = regFile[rs1_index];
    assign rs2_out_data = regFile[rs2_index];
endmodule