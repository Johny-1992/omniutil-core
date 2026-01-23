from fastapi import FastAPI, WebSocket, Depends
from fastapi.middleware.cors import CORSMiddleware
import asyncio
from random import randint

# Imports auth
from api.auth.jwt import create_token
from api.auth.deps import get_user

app = FastAPI(title="OmniUtil API", version="0.1.0")

# CORS pour le frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# =========================
# ROUTES HTTP
# =========================

@app.get("/health")
async def health():
    return {"status": "OK"}

@app.get("/wallets/top")
async def top_wallets():
    return {
        "wallets": [
            {"wallet_id": 32, "merit": 123456, "circulating": 999999},
            {"wallet_id": 12, "merit": 98765, "circulating": 888888},
        ]
    }

@app.post("/login")
def login():
    return {"token": create_token({"user": "admin"})}

@app.get("/secure")
def secure(user=Depends(get_user)):
    return {
        "message": "Authorized",
        "user": user
    }

# =========================
# WEBSOCKETS
# =========================

@app.websocket("/ws/wallets")
async def wallet_ws(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = {
                "wallet_id": 32,
                "merit": randint(100000, 200000),
                "circulating": randint(900000, 1100000),
            }
            await websocket.send_json(data)
            await asyncio.sleep(3)
    except Exception:
        await websocket.close()

@app.websocket("/ws/health")
async def websocket_health(ws: WebSocket):
    await ws.accept()
    try:
        while True:
            await ws.send_json({"status": "alive"})
            await asyncio.sleep(5)
    except Exception:
        await ws.close()
