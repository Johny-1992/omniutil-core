def inspect_partner(system):
    score = 0
    if system.get("api"): score += 40
    if system.get("realtime"): score += 30
    if system.get("kyc_optional"): score += 20
    if system.get("stablecoin_ready"): score += 10

    return {
        "score": score,
        "approved": score >= 60,
        "mode": "FULL" if score >= 80 else "LIMITED"
    }
