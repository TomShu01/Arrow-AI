#!/usr/bin/env python3
"""
WebSocket client to test the Arrow AI Agent protocol with tool execution.

This test simulates the Arrow client:
- Sending user messages with arrow_content
- Receiving function calls from the server
- Responding with function results (including updated arrow_content)

Run this after starting the server with: 
  cd Server
  uvicorn Arrow_AI_Backend.main:app --reload

Then in another terminal:
  cd Server
  python test_websocket.py
"""

import asyncio
import json
import websockets
import sys


async def test_simple():
    """Test simple query that should use tools"""
    return {
        "type": "user_message",
        "message": "Create a dialog node where Elena greets the player and asks about their quest",
        "arrow_content": "<?xml version=\"1.0\"?><arrow></arrow>",
        "history": [],
        "selected_node_ids": [12, 15],
        "current_scene_id": 5,
        "current_project_id": 1
    }


async def test_complex():
    """Test complex query that should trigger planning and multiple tools"""
    return {
        "type": "user_message",
        "message": "Create a branching narrative: First a dialog where Elena offers help, then a hub with three choices (accept, decline, ask why), and connect them all",
        "arrow_content": "<?xml version=\"1.0\"?><arrow></arrow>",
        "history": [],
        "selected_node_ids": [12, 15],
        "current_scene_id": 5,
        "current_project_id": 1
    }


async def test_protocol(test_type="simple"):
    uri = "ws://localhost:8000/ws/chat"
    
    async with websockets.connect(uri) as websocket:
        # 1. Receive connected message
        print("=== Waiting for connected message ===")
        response = await websocket.recv()
        print(f"< {response}")
        data = json.loads(response)
        assert data["type"] == "connected"
        print(f"✓ Connected with session: {data['data']['sessionId']}\n")

        # 2. Send user_message
        print(f"=== Sending user_message ({test_type} test) ===")
        if test_type == "complex":
            user_message = await test_complex()
        else:
            user_message = await test_simple()
        
        await websocket.send(json.dumps(user_message))
        print(f"> Message: {user_message['message']}\n")

        # 3. Receive messages and respond to function calls
        print("=== Listening for server messages ===")
        message_count = 0
        function_call_count = 0
        
        while True:
            response = await websocket.recv()
            data = json.loads(response)
            
            if data["type"] == "chat_response":
                message_count += 1
                print(f"✓ Chat Response {message_count}:")
                print(f"  {data['message']}\n")
                
            elif data["type"] == "function_call":
                function_call_count += 1
                print(f"✓ Function Call {function_call_count}:")
                print(f"  Request ID: {data['request_id']}")
                print(f"  Function: {data['function']}")
                print(f"  Arguments: {json.dumps(data['arguments'], indent=4)}\n")
                
                # Simulate successful execution and send result back
                function_result = {
                    "type": "function_result",
                    "request_id": data["request_id"],
                    "success": True,
                    "arrow_content": "<?xml version=\"1.0\"?><arrow></arrow>",
                    "result": f"Successfully executed {data['function']} (simulated)",
                    "error": ""
                }
                await websocket.send(json.dumps(function_result))
                print(f"✓ Sent function_result for {data['request_id']}\n")
                
            elif data["type"] == "end":
                print(f"✓ Conversation ended")
                print(f"  Total chat responses: {message_count}")
                print(f"  Total function calls: {function_call_count}\n")
                break
                
            else:
                print(f"⚠ Unexpected message type: {data['type']}")
                print(f"  Data: {json.dumps(data, indent=2)}\n")

        # 4. Test stop message
        print("=== Sending stop signal ===")
        stop = {"type": "stop"}
        await websocket.send(json.dumps(stop))
        print(f"> {json.dumps(stop, indent=2)}\n")

        await asyncio.sleep(0.1)

        print("=== ✓ All tests passed! ===")


if __name__ == "__main__":
    # Check for test type argument
    test_type = "simple"
    if len(sys.argv) > 1:
        if sys.argv[1] in ["simple", "complex"]:
            test_type = sys.argv[1]
        else:
            print("Usage: python test_websocket.py [simple|complex]")
            print("  simple  - Test single dialog creation (default)")
            print("  complex - Test complex multi-node scenario")
            sys.exit(1)
    
    try:
        print(f"Running {test_type.upper()} test...\n")
        asyncio.run(test_protocol(test_type))
    except KeyboardInterrupt:
        print("\n\n⚠ Test interrupted by user")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        print("\nMake sure the server is running:")
        print("  cd Server")
        print("  uvicorn Arrow_AI_Backend.main:app --reload")

