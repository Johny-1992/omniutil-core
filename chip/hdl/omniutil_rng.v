module omniutil_rng(
    input clk,
    output reg [31:0] rnd
);
always @(posedge clk) begin
    rnd <= {rnd[30:0], rnd[31] ^ rnd[21] ^ rnd[1] ^ rnd[0]};
end
endmodule
