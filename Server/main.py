from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from uuid import uuid4
import asyncio
from schemas import WSMessage, MessageStartData, PingData
from manager import ConnectionManager
from llm import generate_llm_stream

app = FastAPI()
manager = ConnectionManager()

@app.websocket("/ws/chat")
async def websocket_endpoint(websocket: WebSocket):
    # Simple session system
    session_id = str(uuid4())
    await manager.connect(session_id, websocket)

    await manager.send(session_id, {
        "type": "connected",
        "data": {"sessionId": session_id, "serverTime": int(asyncio.get_event_loop().time() * 1000)}
    })

    try:
        while True:
            raw = await websocket.receive_json()
            event = WSMessage(**raw)

            if event.type == "ping":
                ping = PingData(**event.data)
                latency = int(asyncio.get_event_loop().time() * 1000) - ping.timestamp
                await manager.send(session_id, {"type": "pong", "data": {"latencyMs": latency}})

            elif event.type == "message_start":
                msg_data = MessageStartData(**event.data)
                message_id = str(uuid4())
                await manager.send(session_id, {"type": "message_ack", "data": {"messageId": message_id}})

                try:
                    async for chunk in generate_llm_stream(msg_data.text):
                        await manager.send(session_id, {"type": "message_stream", "data": {"messageId": message_id, "contentChunk": chunk}})

                    await manager.send(session_id, {
                        "type": "message_complete",
                        "data": {"messageId": message_id, "finalContent": "[DONE]", "usage": {"tokens": 42}}
                    })
                except Exception as e:
                    await manager.send(session_id, {"type": "message_error", "data": {"messageId": message_id, "error": str(e)}})

            elif event.type == "message_cancel":
                # you'd track and cancel streaming tasks here
                await manager.send(session_id, {"type": "message_error", "data": {"messageId": "unknown", "error": "Cancelled"}})

            else:
                await manager.send(session_id, {"type": "server_event", "data": {"info": f"Unknown event: {event.type}"}})

    except WebSocketDisconnect:
        manager.disconnect(session_id)
