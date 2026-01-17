module omniutil_secure(
    input clk,
    input [31:0] cmd,
    output reg [31:0] response
);
reg [31:0] merit_balance = 0;

always @(posedge clk) begin
    case(cmd[31:24])
        8'h01: merit_balance <= merit_balance + cmd[23:0];
        8'h02: if (merit_balance >= cmd[23:0])
                  merit_balance <= merit_balance - cmd[23:0];
        8'hFF: response <= merit_balance;
    endcase
end
endmodule
