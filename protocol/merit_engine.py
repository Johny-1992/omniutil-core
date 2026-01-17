class MeritEngine:
    def __init__(self, base_rate=1.0):
        self.base_rate = base_rate
        self.total_supply = 0

    def mint(self, usd_value, partner_factor=1.0):
        merit = usd_value * self.base_rate * partner_factor
        self.total_supply += merit
        return int(merit)
