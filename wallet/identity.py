import hashlib
import os

def generate_uid(seed=None):
    if not seed:
        seed = os.urandom(32)
    return hashlib.sha256(seed).hexdigest()
