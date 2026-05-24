#!/usr/bin/env python3
from fastapi import FastAPI
import uvicorn, os

app = FastAPI(title="NADIA_CLI Agent Manager", version="1.0")

@app.get("/health")
def health():
    return {"status": "ok", "agent": "nadia_cli", "owner": "User"}

@app.post("/webhook/telegram")
def telegram_webhook(data: dict):
    return {"received": True}

if __name__ == "__main__":
    port = int(os.getenv("AGENT_MANAGER_PORT", 3600))
    uvicorn.run(app, host="127.0.0.1", port=port)
