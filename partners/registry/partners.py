PARTNERS = {}

def register_partner(partner_id, data, ai_result):
    PARTNERS[partner_id] = {
        "data": data,
        "status": ai_result["mode"],
        "score": ai_result["score"]
    }
