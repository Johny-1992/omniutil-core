class Wallet:
    def __init__(self, wallet_id):
        self.wallet_id = wallet_id
        self.balances = {"MERIT": 0}

    def credit(self, asset, amount):
        self.balances[asset] = self.balances.get(asset, 0) + amount

    def debit(self, asset, amount):
        if self.balances.get(asset, 0) < amount:
            raise Exception("Insufficient balance")
        self.balances[asset] -= amount
