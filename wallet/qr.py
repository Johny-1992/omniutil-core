def generate_payment_qr(uid, amount, asset="MERIT"):
    return f"OMNIUTIL:PAY:{uid}:{amount}:{asset}"
