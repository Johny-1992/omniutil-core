import uuid
from datetime import datetime

def generate_partner_qr(partner_name):
    partner_id = str(uuid.uuid4())
    payload = {
        "partner_id": partner_id,
        "name": partner_name,
        "timestamp": datetime.utcnow().isoformat(),
        "capabilities_required": [
            "real_time_transactions",
            "user_wallet_mapping",
            "usd_conversion"
        ]
    }
    return payload

if __name__ == "__main__":
    print(generate_partner_qr("TEST_PARTNER"))
