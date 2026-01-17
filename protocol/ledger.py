import hashlib
import time

class LedgerEntry:
    def __init__(self, sender, receiver, amount, asset):
        self.sender = sender
        self.receiver = receiver
        self.amount = amount
        self.asset = asset
        self.timestamp = time.time()
        self.hash = self.compute_hash()

    def compute_hash(self):
        payload = f"{self.sender}{self.receiver}{self.amount}{self.asset}{self.timestamp}"
        return hashlib.sha256(payload.encode()).hexdigest()
