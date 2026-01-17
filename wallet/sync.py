def sync_transactions(offline_txs, ledger):
    for tx in offline_txs:
        ledger.append(tx)
