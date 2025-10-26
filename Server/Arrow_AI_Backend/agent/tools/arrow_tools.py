"""
Arrow Tools - Simplified tools for narrative design operations
These tools send function calls via WebSocket to the Arrow client
"""

from langchain_core.tools import tool
from typing import Dict, Any, Literal
import asyncio
import uuid
from Arrow_AI_Backend.manager import manager


# Store current session context (will be set by the agent)
current_context: Dict[str, Any] = {}

# Store pending function calls waiting for results
# Maps request_id -> asyncio.Future
pending_calls: Dict[str, asyncio.Future] = {}


def set_context(session_id: str, scene_id: int = None, arrow_file: str = None):
    """Set the current execution context for tools"""
    current_context["session_id"] = session_id
    current_context["scene_id"] = scene_id
    current_context["arrow_file"] = arrow_file


def get_arrow_file() -> str:
    """Get the current arrow file from context as JSON string"""
    return current_context.get("arrow_file", "")


def get_context_value(key: str) -> Any:
    """Get a specific value from the current context"""
    return current_context.get(key)


def set_function_result(request_id: str, success: bool, result: Any = None, error: str = None):
    """
    Called when a function result arrives from the client.
    Resolves the pending Future for that request.
    """
    future = pending_calls.get(request_id)
    if future and not future.done():
        if success:
            future.set_result(result)
        else:
            future.set_exception(Exception(error or "Function call failed"))
        pending_calls.pop(request_id, None)


async def send_function_call(function_name: str, arguments: Dict[str, Any]) -> str:
    """
    Send a function call to the client via WebSocket and wait for the result.
    This function will block until the client sends back a function_result message.
    """
    session_id = current_context.get("session_id")
    if not session_id:
        raise Exception("No session context set")
    
    # Generate request ID
    request_id = str(uuid.uuid4())
    
    # Create a Future to wait for the result
    future = asyncio.get_event_loop().create_future()
    pending_calls[request_id] = future
    
    # Send function call to client
    await manager.send(session_id, {
        "type": "function_call",
        "request_id": request_id,
        "function": function_name,
        "arguments": arguments
    })
    
    print(f"[Tools] Sent function call {function_name} with request_id {request_id}, waiting for result...")
    
    # Wait for the result (with timeout)
    try:
        result = await asyncio.wait_for(future, timeout=30.0)
        print(f"[Tools] Received result for {request_id}: {result}")
        return str(result)
    except asyncio.TimeoutError:
        pending_calls.pop(request_id, None)
        raise Exception(f"Timeout waiting for function result: {function_name}")
    except Exception as e:
        pending_calls.pop(request_id, None)
        raise


# ========== Node Creation Tools ==========

@tool
async def create_dialog_node(
    character_id: int,
    lines: list[str],
    name: str = "",
    scene_id: int = None
) -> str:
    """
    Create a dialog node with character speech.
    
    Args:
        character_id: ID of the character speaking (-1 for anonymous)
        lines: List of dialog lines to display
        name: Optional custom name for the node
        scene_id: Scene to create in (defaults to current scene)
    """
    return await send_function_call("create_insert_node", {
        "type": "dialog",
        "name": name,
        "scene_id": scene_id or current_context.get("scene_id"),
        "preset": {
            "character": character_id,
            "lines": lines,
            "playable": True
        }
    })


@tool
async def create_content_node(
    title: str,
    content: str,
    name: str = "",
    auto_play: bool = False,
    scene_id: int = None
) -> str:
    """
    Create a content node to display narrative text.
    
    Args:
        title: Title of the content
        content: Main text content to display
        name: Optional custom name for the node
        auto_play: Whether to auto-advance to next node
        scene_id: Scene to create in (defaults to current scene)
    """
    return await send_function_call("create_insert_node", {
        "type": "content",
        "name": name,
        "scene_id": scene_id or current_context.get("scene_id"),
        "preset": {
            "title": title,
            "content": content,
            "brief": 50,
            "auto_play": auto_play,
            "clear": False
        }
    })


@tool
async def create_hub_node(
    options: list[str],
    name: str = "",
    scene_id: int = None
) -> str:
    """
    Create a hub node for multiple choice branching.
    
    Args:
        options: List of choice options to present to player
        name: Optional custom name for the node
        scene_id: Scene to create in (defaults to current scene)
    """
    return await send_function_call("create_insert_node", {
        "type": "hub",
        "name": name,
        "scene_id": scene_id or current_context.get("scene_id"),
        "preset": {
            "options": options
        }
    })


@tool
async def create_condition_node(
    variable_id: int,
    operator: Literal["==", "!=", ">", "<", ">=", "<="],
    compare_value: int | float | str | bool,
    name: str = "",
    scene_id: int = None
) -> str:
    """
    Create a condition node for branching based on variable comparison.
    Output slot 0 = true, slot 1 = false.
    
    Args:
        variable_id: ID of the variable to check
        operator: Comparison operator (==, !=, >, <, >=, <=)
        compare_value: Value to compare against
        name: Optional custom name for the node
        scene_id: Scene to create in (defaults to current scene)
    """
    return await send_function_call("create_insert_node", {
        "type": "condition",
        "name": name,
        "scene_id": scene_id or current_context.get("scene_id"),
        "preset": {
            "variable": variable_id,
            "operator": operator,
            "compare_to": {
                "type": "value",
                "value": compare_value
            }
        }
    })


@tool
async def create_variable_update_node(
    variable_id: int,
    operation: Literal["set", "add", "subtract", "multiply", "divide"],
    value: int | float,
    name: str = "",
    scene_id: int = None
) -> str:
    """
    Create a node to update a variable's value.
    
    Args:
        variable_id: ID of the variable to update
        operation: Operation to perform (set, add, subtract, multiply, divide)
        value: Value to use in the operation
        name: Optional custom name for the node
        scene_id: Scene to create in (defaults to current scene)
    """
    return await send_function_call("create_insert_node", {
        "type": "variable_update",
        "name": name,
        "scene_id": scene_id or current_context.get("scene_id"),
        "preset": {
            "variable": variable_id,
            "operation": operation,
            "value": {
                "type": "value",
                "value": value
            }
        }
    })


# ========== Connection Tools ==========

@tool
async def create_connection(
    from_node_id: int,
    to_node_id: int,
    from_slot: int = 0,
    to_slot: int = 0
) -> str:
    """
    Create a connection between two nodes.
    
    Args:
        from_node_id: ID of the source node
        to_node_id: ID of the target node
        from_slot: Output slot index on source node (default: 0)
        to_slot: Input slot index on target node (default: 0)
    """
    # Use update_node_map to add connection
    return await send_function_call("update_node_map", {
        "node_id": from_node_id,
        "scene_id": current_context.get("scene_id"),
        "modifications": {
            "io": {
                "push": [[from_node_id, from_slot, to_node_id, to_slot]]
            }
        }
    })


# ========== Variable Tools ==========

@tool
async def create_variable(
    name: str,
    var_type: Literal["num", "str", "bool"],
    initial_value: int | float | str | bool,
    notes: str = ""
) -> str:
    """
    Create a new global variable.
    
    Args:
        name: Name of the variable
        var_type: Type of variable (num, str, bool)
        initial_value: Starting value for the variable
        notes: Optional description/notes
    """
    return await send_function_call("create_variable", {
        "name": name,
        "type": var_type,
        "initial_value": initial_value,
        "notes": notes
    })


# ========== Character Tools ==========

@tool
async def create_character(
    name: str,
    color: str = "#4A90E2",
    tags: dict = None,
    notes: str = ""
) -> str:
    """
    Create a new character.
    
    Args:
        name: Name of the character
        color: Display color as hex string (default: blue)
        tags: Optional tags/metadata for the character
        notes: Optional description/notes
    """
    return await send_function_call("create_character", {
        "name": name,
        "color": color,
        "tags": tags or {},
        "notes": notes
    })


# List of all tools for the executor
ARROW_TOOLS = [
    create_dialog_node,
    create_content_node,
    create_hub_node,
    create_condition_node,
    create_variable_update_node,
    create_connection,
    create_variable,
    create_character,
]

