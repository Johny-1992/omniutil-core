import uuid
from datetime import datetime, UTC

class OmniUtilCore:
    def __init__(self, partner_id, reward_rate):
        self.partner_id = partner_id
        self.reward_rate = reward_rate

    def process_transaction(self, user_id, amount_usd):
        merit = amount_usd * self.reward_rate
        return {
            "tx_id": str(uuid.uuid4()),
            "partner_id": self.partner_id,
            "user_id": user_id,
            "amount_usd": amount_usd,
            "merit_generated": merit,
            "timestamp": datetime.now(UTC).isoformat()
        }
