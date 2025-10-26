from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from uuid import uuid4
import asyncio
from typing import Dict, Any
from Arrow_AI_Backend.schemas import (
    FileSyncMessage,
    UserMessage,
    FunctionResultMessage,
    StopMessage,
)
from Arrow_AI_Backend.manager import manager
from Arrow_AI_Backend.agent.agents.supervisor import supervisor_agent

app = FastAPI()

# Store project state per session
session_state: Dict[str, Dict[str, Any]] = {}


@app.websocket("/ws/chat")
async def websocket_endpoint(websocket: WebSocket):
    """
    WebSocket endpoint for Arrow AI Agent protocol.
    Handles file sync, user messages, function results, and stop signals.
    """
    session_id = str(uuid4())
    await manager.connect(session_id, websocket)
    
    # Initialize session state
    session_state[session_id] = {
        "arrow_content": "",
        "project_id": None,
        "current_scene_id": None,
    }

    # Send connected message
    await manager.send(session_id, {
        "type": "connected",
        "data": {
            "sessionId": session_id,
            "serverTime": int(asyncio.get_event_loop().time() * 1000)
        }
    })

    try:
        while True:
            raw = await websocket.receive_json()
            message_type = raw.get("type")

            # ========== Handle File Sync ==========
            if message_type == "file_sync":
                msg = FileSyncMessage(**raw)
                session_state[session_id]["arrow_content"] = msg.arrow_content
                session_state[session_id]["project_id"] = msg.project_id
                print(f"[{session_id}] File synced for project {msg.project_id}")

            # ========== Handle User Message ==========
            elif message_type == "user_message":
                msg = UserMessage(**raw)
                
                # Update session context
                if msg.current_scene_id:
                    session_state[session_id]["current_scene_id"] = msg.current_scene_id
                if msg.current_project_id:
                    session_state[session_id]["project_id"] = msg.current_project_id

                print(f"[{session_id}] User message: {msg.message}")
                
                try:
                    await supervisor_agent.ainvoke({
                        "session_id": session_id,
                        "message_id": str(uuid4()),
                        "input": msg.message,
                        "complexity": "",  # Will be set by analyzer
                        "plan": [],
                        "past_steps": [],
                        "response": ""
                    })
                    
                    await manager.send(session_id, {
                        "type": "end"
                    })
                    
                except Exception as e:
                    print(f"[{session_id}] Error processing message: {e}")
                    import traceback
                    traceback.print_exc()
                    await manager.send(session_id, {
                        "type": "chat_response",
                        "message": f"Error: {str(e)}"
                    })
                    await manager.send(session_id, {
                        "type": "end"
                    })

            # ========== Handle Function Result ==========
            elif message_type == "function_result":
                msg = FunctionResultMessage(**raw)
                print(f"[{session_id}] Function result for {msg.request_id}: success={msg.success}")
                # TODO: Handle function results in agent conversation flow

            # ========== Handle Stop Signal ==========
            elif message_type == "stop":
                msg = StopMessage(**raw)
                print(f"[{session_id}] Stop signal received")

            # ========== Unknown Message Type ==========
            else:
                print(f"[{session_id}] Unknown message type: {message_type}")

    except (WebSocketDisconnect, RuntimeError) as e:
        # Handle both clean disconnects and connection errors
        print(f"[{session_id}] WebSocket disconnected: {e}")
        manager.disconnect(session_id)
        session_state.pop(session_id, None)
