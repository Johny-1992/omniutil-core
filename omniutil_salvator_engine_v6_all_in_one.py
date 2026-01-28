#!/usr/bin/env python3
import os, json, time, hashlib, subprocess, requests
from datetime import datetime, timezone
from pathlib import Path

from dotenv import load_dotenv
from eth_account import Account
from eth_account.messages import encode_defunct

# =========================
# INIT
# =========================
BASE_DIR = Path(__file__).resolve().parent
LOGS = BASE_DIR / "logs"
PUBLIC = BASE_DIR / "public"
DATA = BASE_DIR / "data"

for d in [LOGS, PUBLIC, DATA]:
    d.mkdir(exist_ok=True)

load_dotenv()

INTERVAL_MINUTES = int(os.getenv("OMNI_INTERVAL_MINUTES", "30"))

REQUIRED_ENV = [
    "PRIVATE_KEY",
    "CONTRACT_ADDRESS",
    "OMNI_NAME",
    "OMNI_SYMBOL"
]

missing = [k for k in REQUIRED_ENV if not os.getenv(k)]
if missing:
    raise SystemExit(f"❌ Missing env vars: {', '.join(missing)}")

PRIVATE_KEY = os.getenv("PRIVATE_KEY")
CONTRACT = os.getenv("CONTRACT_ADDRESS")
OMNI_NAME = os.getenv("OMNI_NAME")
OMNI_SYMBOL = os.getenv("OMNI_SYMBOL")

ACCOUNT = Account.from_key(PRIVATE_KEY)
SIGNER = ACCOUNT.address

STATE_FILE = DATA / "salvator_state.json"
PROOF_FILE = PUBLIC / "proof_of_presence.json"

# =========================
# UTILS
# =========================
def now():
    return datetime.now(timezone.utc).isoformat()

def sh(cmd):
    return subprocess.call(cmd, shell=True)

def load_state():
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {}

def save_state(state):
    STATE_FILE.write_text(json.dumps(state, indent=2))

def ttl_ok(state, key, ttl_h=24):
    last = state.get(key)
    if not last:
        return False
    delta = datetime.now(timezone.utc) - datetime.fromisoformat(last)
    return delta.total_seconds() < ttl_h * 3600

def mark(state, key):
    state[key] = now()
    save_state(state)

# =========================
# CRYPTO PROOF
# =========================
def build_proof():
    payload = {
        "timestamp": now(),
        "contract": CONTRACT,
        "name": OMNI_NAME,
        "symbol": OMNI_SYMBOL,
        "signer": SIGNER
    }

    raw = json.dumps(payload, sort_keys=True).encode()
    payload_hash = hashlib.sha256(raw).hexdigest()

    message = encode_defunct(text=payload_hash)
    signed = Account.sign_message(message, PRIVATE_KEY)

    proof = {
        **payload,
        "hash": payload_hash,
        "signature": signed.signature.hex(),
        "signature_type": "EIP-191"
    }

    return proof

def append_proof(proof):
    data = []
    if PROOF_FILE.exists():
        data = json.loads(PROOF_FILE.read_text())
    data.append(proof)
    PROOF_FILE.write_text(json.dumps(data, indent=2))

# =========================
# IPFS (OPTIONAL)
# =========================
def try_ipfs(path):
    try:
        r = subprocess.check_output(["ipfs", "add", "-Q", str(path)])
        return r.decode().strip()
    except Exception:
        return None

# =========================
# PRESENCE SCORE
# =========================
def compute_presence_score():
    score = 0
    if PROOF_FILE.exists(): score += 25
    if (PUBLIC / "sitemap.xml").exists(): score += 15
    if (PUBLIC / "meta").exists(): score += 15
    if os.getenv("BSCSCAN_API_KEY"): score += 10
    if os.getenv("BSC_RPC_URL"): score += 10
    if os.getenv("OMNIUTIL_CORE_V2_ADDRESS"): score += 10
    return min(score, 100)

# =========================
# MAIN LOOP
# =========================
def run_cycle():
    state = load_state()

    print(f"[{now()}] 🧠 OMNIUTIL SALVATOR ENGINE V6 START")
    print(f"[{now()}] CONTRACT = {CONTRACT}")
    print(f"[{now()}] SIGNER = {SIGNER}")

    if not ttl_ok(state, "proof"):
        proof = build_proof()
        append_proof(proof)
        ipfs_hash = try_ipfs(PROOF_FILE)
        if ipfs_hash:
            proof["ipfs"] = ipfs_hash
        mark(state, "proof")
        print(f"[OK] Proof signed & stored")

    if not ttl_ok(state, "seo"):
        sh("python3 generate_sitemap.py")
        sh("bash omniutil_super_seo_listing_plus.sh")
        mark(state, "seo")

    score = compute_presence_score()
    (PUBLIC / "presence_score.json").write_text(json.dumps({
        "timestamp": now(),
        "score": score,
        "contract": CONTRACT
    }, indent=2))

    final_hash = hashlib.sha256(
        json.dumps(load_state(), sort_keys=True).encode()
    ).hexdigest()

    print(f"[{now()}] 📊 PRESENCE SCORE = {score}/100")
    print(f"[{now()}] 🔐 FINAL HASH = {final_hash}")
    print(f"[{now()}] ✅ CYCLE DONE\n")

# =========================
# WATCHDOG
# =========================
if __name__ == "__main__":
    while True:
        try:
            run_cycle()
        except Exception as e:
            print(f"[ERROR] {e}")
        print(f"[WATCHDOG] Sleeping {INTERVAL_MINUTES} minutes\n")
        time.sleep(INTERVAL_MINUTES * 60)
