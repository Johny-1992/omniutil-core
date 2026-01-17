import hashlib

def hash_pin(pin):
    return hashlib.sha256(pin.encode()).hexdigest()
