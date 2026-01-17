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
