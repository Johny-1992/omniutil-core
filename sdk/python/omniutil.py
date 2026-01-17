from uuid import uuid4
from datetime import datetime, UTC

def process_transaction(partner_id, user_id, amount_usd, reward_rate):
    return {
        "tx_id": str(uuid4()),
        "partner_id": partner_id,
        "user_id": user_id,
        "amount_usd": amount_usd,
        "merit_generated": amount_usd * reward_rate,
        "timestamp": datetime.now(UTC).isoformat()
    }
