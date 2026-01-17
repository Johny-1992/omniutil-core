#!/bin/bash
set -e

echo "🚀 Initializing OmniUtil Secure Chip Core..."

mkdir -p chip/{hdl,firmware,protocol,testbench,docs}

cat > chip/hdl/omniutil_rng.v << 'EOF'
module omniutil_rng(
    input clk,
    output reg [31:0] rnd
);
always @(posedge clk) begin
    rnd <= {rnd[30:0], rnd[31] ^ rnd[21] ^ rnd[1] ^ rnd[0]};
end
endmodule
EOF

cat > chip/hdl/omniutil_secure.v << 'EOF'
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
EOF

cat > chip/firmware/main.c << 'EOF'
#include "wallet.h"
#include "protocol.h"

int main() {
    omni_init();
    while(1) {
        handle_apdu();
    }
    return 0;
}
EOF

cat > chip/firmware/wallet.c << 'EOF'
unsigned int merit = 0;

void credit(unsigned int amount) {
    merit += amount;
}

void debit(unsigned int amount) {
    if (merit >= amount) merit -= amount;
}
EOF

cat > chip/firmware/protocol.c << 'EOF'
void handle_apdu() {
    // APDU command handler (stub)
}
EOF

cat > chip/protocol/apdu.md << 'EOF'
# OmniUtil APDU Protocol

01 | CREDIT | amount  
02 | DEBIT  | amount  
FF | BALANCE | -
EOF

cat > chip/docs/chip_architecture.md << 'EOF'
OmniUtil Secure Chip Architecture

- Offline-first
- Non-custodial
- Anti-replay counters
- Hardware root of trust
EOF

echo "✅ OmniUtil Secure Chip Core initialized successfully."
