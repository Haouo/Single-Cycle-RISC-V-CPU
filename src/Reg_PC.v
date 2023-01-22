module Reg_PC(
    input clk,
    input rst,
    input [31:0] next_pc,
    output reg [31:0] current_pc
);
    // main part
    always@ (posedge clk) begin
        if(rst == 1)
            current_pc <= 32'd0;
        else
            current_pc <= next_pc;
    end
endmodule