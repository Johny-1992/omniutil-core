def generate_qr_payload(wallet_id, amount, asset="MERIT"):
    return f"OMNIUTIL:{wallet_id}:{amount}:{asset}"
