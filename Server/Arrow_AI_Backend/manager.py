from typing import Dict
from fastapi import WebSocket
from starlette.websockets import WebSocketDisconnect, WebSocketState

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
        """Send message to websocket, handling disconnection gracefully"""
        ws = self.active_connections.get(session_id)
        if ws:
            try:
                # Check if websocket is still connected
                if ws.client_state == WebSocketState.CONNECTED:
                    await ws.send_json(message)
                else:
                    print(f"[!] WebSocket {session_id} is not connected (state: {ws.client_state})")
                    self.disconnect(session_id)
            except (WebSocketDisconnect, RuntimeError, Exception) as e:
                print(f"[!] Error sending to {session_id}: {type(e).__name__}: {e}")
                self.disconnect(session_id)

manager = ConnectionManager()
