#!/bin/bash
set -e

echo "🔐 Initializing OmniUtil Wallet Core..."

WALLET_DIR="wallet"

cat > $WALLET_DIR/identity.py << 'EOF'
import hashlib
import os

def generate_uid(seed=None):
    if not seed:
        seed = os.urandom(32)
    return hashlib.sha256(seed).hexdigest()
EOF

cat > $WALLET_DIR/omniwallet.py << 'EOF'
from wallet.identity import generate_uid

class OmniWallet:
    def __init__(self):
        self.uid = generate_uid()
        self.balances = {"MERIT": 0}
        self.nonce = 0

    def credit(self, asset, amount):
        self.balances[asset] = self.balances.get(asset, 0) + amount

    def debit(self, asset, amount):
        if self.balances.get(asset, 0) < amount:
            raise Exception("Insufficient balance")
        self.balances[asset] -= amount
        self.nonce += 1
EOF

cat > $WALLET_DIR/qr.py << 'EOF'
def generate_payment_qr(uid, amount, asset="MERIT"):
    return f"OMNIUTIL:PAY:{uid}:{amount}:{asset}"
EOF

cat > $WALLET_DIR/offline_cache.py << 'EOF'
class OfflineCache:
    def __init__(self):
        self.pending_tx = []

    def add(self, tx):
        self.pending_tx.append(tx)

    def flush(self):
        txs = self.pending_tx
        self.pending_tx = []
        return txs
EOF

cat > $WALLET_DIR/sync.py << 'EOF'
def sync_transactions(offline_txs, ledger):
    for tx in offline_txs:
        ledger.append(tx)
EOF

cat > $WALLET_DIR/limits.py << 'EOF'
MAX_OFFLINE_TX = 5
MAX_OFFLINE_AMOUNT = 100
EOF

echo "✅ OmniUtil Wallet Core ready."
