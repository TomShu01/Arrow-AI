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

# Store running agent tasks per session
# Maps session_id -> asyncio.Task
running_agents: Dict[str, asyncio.Task] = {}


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
                
                # Cancel any running agent for this session
                if session_id in running_agents:
                    running_agents[session_id].cancel()
                    running_agents.pop(session_id, None)
                
                # Create and run agent in background task
                async def run_agent():
                    try:
                        # Create initial state
                        initial_state = {
                            "session_id": session_id,
                            "message_id": str(uuid4()),
                            "input": msg.message,
                            "complexity": "",  # Will be set by analyzer
                            "plan": [],
                            "past_steps": [],
                            "response": "",
                            "replan_reason": "",
                            "pending_request_id": None,
                            "function_result": None,
                            "current_scene_id": msg.current_scene_id
                        }
                        
                        # Invoke supervisor agent
                        await supervisor_agent.ainvoke(initial_state)
                        
                        await manager.send(session_id, {
                            "type": "end"
                        })
                        
                    except asyncio.CancelledError:
                        print(f"[{session_id}] Agent task cancelled")
                        raise
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
                    finally:
                        # Clean up task reference
                        running_agents.pop(session_id, None)
                
                # Start agent task in background
                task = asyncio.create_task(run_agent())
                running_agents[session_id] = task

            # ========== Handle Function Result ==========
            elif message_type == "function_result":
                msg = FunctionResultMessage(**raw)
                print(f"[{session_id}] Function result for {msg.request_id}: success={msg.success}")
                
                # Resolve the pending Future for this function call
                # This allows the tool to continue execution
                from Arrow_AI_Backend.agent.tools.arrow_tools import set_function_result
                
                set_function_result(
                    request_id=msg.request_id,
                    success=msg.success,
                    result=msg.result,
                    error=msg.error
                )
                
                if msg.success:
                    print(f"[{session_id}] Function succeeded: {msg.result}")
                else:
                    print(f"[{session_id}] Function failed: {msg.error}")

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
        
        # Cancel running agent if any
        if session_id in running_agents:
            running_agents[session_id].cancel()
            running_agents.pop(session_id, None)
        
        manager.disconnect(session_id)
        session_state.pop(session_id, None)
