module LD_Filter(
    input [2:0] func3,
    input [31:0] in_data,
    output [31:0] out_data
);
    // func3 map for LOAD inst.
    parameter   LB = 3'b000,
                LH = 3'b001,
                LW = 3'b010,
                LBU = 3'b100,
                LHU = 3'b101;
    // temp reg 
    reg [31:0] temp_out;

    // main part
    always@(*) begin
        case(func3)
            LB: temp_out = $signed(in_data[7:0]); // signed extend
            LH: temp_out = $signed(in_data[15:0]); // signed extend
            LW: temp_out = in_data;
            LBU: temp_out = {24'b0, in_data[7:0]}; // zero extend
            LHU: temp_out = {16'b0, in_data[15:0]};  // zero extend
            default: temp_out = 32'b0;
        endcase
    end
    assign out_data = temp_out;
endmodule