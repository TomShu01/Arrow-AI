#!/usr/bin/env python3
"""
Simple WebSocket client to test the Arrow AI Agent protocol.
Run this after starting the server with: uvicorn Arrow_AI_Backend.main:app --reload
"""

import asyncio
import json
import websockets


async def test_protocol():
    uri = "ws://localhost:8000/ws/chat"
    
    async with websockets.connect(uri) as websocket:
        # 1. Receive connected message
        print("=== Waiting for connected message ===")
        response = await websocket.recv()
        print(f"< {response}")
        data = json.loads(response)
        assert data["type"] == "connected"
        print(f"✓ Connected with session: {data['data']['sessionId']}\n")

        # 2. Send file_sync message
        print("=== Sending file_sync ===")
        file_sync = {
            "type": "file_sync",
            "project_id": 1,
            "arrow_content": "<?xml version=\"1.0\"?><arrow></arrow>",
            "timestamp": 1698765432
        }
        await websocket.send(json.dumps(file_sync))
        print(f"> {json.dumps(file_sync, indent=2)}\n")

        # Give server time to process
        await asyncio.sleep(0.1)

        # 3. Send user_message (complex query to trigger planner)
        print("=== Sending user_message ===")
        user_message = {
            "type": "user_message",
            "message": "Create a branching narrative sequence where the protagonist enters a mysterious temple. First, add an entry dialog where they describe the ancient carvings on the walls. Then create three different dialog options: one where they investigate the altar, another where they examine the murals, and a third where they search for hidden passages. Each choice should lead to a unique consequence with appropriate content nodes showing what they discover. Finally, add a hub node that brings all three paths back together where the protagonist realizes the temple is a test of wisdom.",
            "history": [],
            "selected_node_ids": [12, 15],
            "current_scene_id": 5,
            "current_project_id": 1
        }
        await websocket.send(json.dumps(user_message))
        print(f"> {json.dumps(user_message, indent=2)}\n")

        # 4. Receive all chat_response messages until end
        print("=== Waiting for chat responses ===")
        message_count = 0
        while True:
            response = await websocket.recv()
            data = json.loads(response)
            
            if data["type"] == "chat_response":
                message_count += 1
                print(f"✓ Response {message_count}: {data['message']}\n")
            elif data["type"] == "end":
                print(f"✓ Conversation ended (received {message_count} messages)\n")
                break
            else:
                print(f"⚠ Unexpected message type: {data['type']}\n")

        # 6. Test function_result message (server just logs it for now)
        print("=== Sending function_result ===")
        function_result = {
            "type": "function_result",
            "request_id": "req_12345",
            "success": True,
            "result": "Node created successfully",
            "error": ""
        }
        await websocket.send(json.dumps(function_result))
        print(f"> {json.dumps(function_result, indent=2)}\n")

        await asyncio.sleep(0.1)

        # 7. Test stop message
        print("=== Sending stop signal ===")
        stop = {"type": "stop"}
        await websocket.send(json.dumps(stop))
        print(f"> {json.dumps(stop, indent=2)}\n")

        await asyncio.sleep(0.1)

        print("=== All tests passed! ===")


if __name__ == "__main__":
    try:
        asyncio.run(test_protocol())
    except Exception as e:
        print(f"\n❌ Error: {e}")
        print("\nMake sure the server is running:")
        print("  cd Server")
        print("  uvicorn Arrow_AI_Backend.main:app --reload")

