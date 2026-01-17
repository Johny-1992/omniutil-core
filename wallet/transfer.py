from protocol.ledger import LedgerEntry

def transfer(sender_wallet, receiver_wallet, amount, asset="MERIT"):
    sender_wallet.debit(asset, amount)
    receiver_wallet.credit(asset, amount)
    return LedgerEntry(sender_wallet.wallet_id, receiver_wallet.wallet_id, amount, asset)
