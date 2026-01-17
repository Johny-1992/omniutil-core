class OfflineCache:
    def __init__(self):
        self.pending_tx = []

    def add(self, tx):
        self.pending_tx.append(tx)

    def flush(self):
        txs = self.pending_tx
        self.pending_tx = []
        return txs
