from typing import Dict
from fastapi import WebSocket

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, session_id: str, websocket: WebSocket):
        await websocket.accept()
        self.active_connections[session_id] = websocket
        print(f"[+] Connected: {session_id}")

    def disconnect(self, session_id: str):
        self.active_connections.pop(session_id, None)
        print(f"[-] Disconnected: {session_id}")

    async def send(self, session_id: str, message: dict):
        ws = self.active_connections.get(session_id)
        if ws:
            await ws.send_json(message)
