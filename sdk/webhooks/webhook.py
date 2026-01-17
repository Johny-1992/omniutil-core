def emit_webhook(event, endpoint):
    print(f"[WEBHOOK] Sending {event['tx_id']} to {endpoint}")
