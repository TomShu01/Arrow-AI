"""
Arrow Tools - Simplified tools for narrative design operations
These tools send function calls via WebSocket to the Arrow client
"""

from langchain_core.tools import tool
from typing import Dict, Any, Literal
import asyncio
import uuid
from Arrow_AI_Backend.manager import manager
import json


# Store current session context (will be set by the agent)
current_context: Dict[str, Any] = {}

# Store pending function calls waiting for results
# Maps request_id -> asyncio.Future
pending_calls: Dict[str, asyncio.Future] = {}


def set_context(session_id: str, scene_id: int = None, arrow_file: str = None):
    """Set the current execution context for tools"""
    current_context["session_id"] = session_id
    current_context["scene_id"] = scene_id
    if arrow_file:
        try:
            if isinstance(arrow_file, str):
                current_context["arrow_file"] = json.loads(arrow_file)
            else:
                current_context["arrow_file"] = arrow_file
        except json.JSONDecodeError as e:
            print(f"[Tools] Error parsing arrow_file JSON: {e}")
            print(f"[Tools] Arrow file content (first 200 chars): {arrow_file[:200] if isinstance(arrow_file, str) else 'Not a string'}")
            current_context["arrow_file"] = {}


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
    
    
    # Wait for the result (with timeout)
    try:
        result = await asyncio.wait_for(future, timeout=30.0)
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
            "data": {
                "character": character_id,
                "lines": lines,
                "playable": True
            }
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
            "data": {
                "title": title,
                "content": content,
                "brief": 50,
                "auto_play": auto_play,
                "clear": False
            }
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
            "data": {
                "options": options
            }
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
            "data": {
                "variable": variable_id,
                "operator": operator,
                "compare_to": {
                    "type": "value",
                    "value": compare_value
                }
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
            "data": {
                "variable": variable_id,
                "operation": operation,
                "value": {
                    "type": "value",
                    "value": value
                }
            }
        }
    })


# ========== Node Update/Delete Tools ==========

@tool
async def update_node(
    node_id: int,
    name: str = None,
    data: dict = None,
    notes: str = None
) -> str:
    """
    Update an existing node's properties.
    
    Args:
        node_id: ID of the node to update
        name: Optional new name for the node
        data: Optional partial data update (merged with existing)
        notes: Optional new notes
    """
    args = {"node_id": node_id}
    if name is not None and name != "":
        args["name"] = name
    if data is not None:
        args["data"] = data
    if notes is not None and notes != "":
        args["notes"] = notes
    
    return await send_function_call("update_node", args)


@tool
async def delete_node(
    node_id: int,
    force: bool = False
) -> str:
    """
    Delete a node from the scene.
    
    Args:
        node_id: ID of the node to delete
        force: If true, breaks references to this node
    """
    return await send_function_call("delete_node", {
        "node_id": node_id,
        "force": force
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
    Create a connection between two nodes to establish narrative flow.
    
    CRITICAL: All nodes must be connected to work in the story. A node without 
    connections is orphaned and will never execute.
    
    Args:
        from_node_id: ID of the source node (where the connection starts)
        to_node_id: ID of the target node (where the connection goes to)
        from_slot: Output slot index on source node (default: 0)
                   - For most nodes, use 0
                   - For hub nodes: 0 = first choice, 1 = second choice, etc.
                   - For condition nodes: 0 = true branch, 1 = false branch
        to_slot: Input slot index on target node (default: 0, rarely changed)
    
    Returns:
        Success message confirming the connection was created and drawn on the graph.
    
    Example:
        create_connection(from_node_id=2, to_node_id=4)  # Simple connection
        create_connection(from_node_id=5, to_node_id=6, from_slot=1)  # Hub choice 2
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


@tool
async def delete_connection(
    from_node_id: int,
    to_node_id: int,
    from_slot: int = 0,
    to_slot: int = 0
) -> str:
    """
    Remove a connection between two nodes.
    
    WARNING: Deleting a connection may orphan a node, making it unreachable 
    in the narrative flow.
    
    Args:
        from_node_id: ID of the source node (where the connection starts)
        to_node_id: ID of the target node (where the connection goes to)
        from_slot: Output slot index on source node (default: 0)
        to_slot: Input slot index on target node (default: 0)
    
    Returns:
        Success message confirming the connection was removed from both 
        the data and the visual graph.
    """
    return await send_function_call("update_node_map", {
        "node_id": from_node_id,
        "scene_id": current_context.get("scene_id"),
        "modifications": {
            "io": {
                "pop": [[from_node_id, from_slot, to_node_id, to_slot]]
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
    args = {"type": var_type}
    if name:
        args["name"] = name
    if initial_value is not None:
        args["initial_value"] = initial_value
    if notes:
        args["notes"] = notes
    
    return await send_function_call("create_variable", args)


@tool
async def update_variable(
    variable_id: int,
    name: str = None,
    initial_value: int | float | str | bool = None,
    notes: str = None
) -> str:
    """
    Update an existing variable's properties.
    
    Args:
        variable_id: ID of the variable to update
        name: Optional new name
        initial_value: Optional new initial value
        notes: Optional new notes
    """
    args = {"variable_id": variable_id}
    if name is not None and name != "":
        args["name"] = name
    if initial_value is not None:
        args["initial_value"] = initial_value
    if notes is not None and notes != "":
        args["notes"] = notes
    
    return await send_function_call("update_variable", args)


@tool
async def delete_variable(
    variable_id: int,
    force: bool = False
) -> str:
    """
    Delete a variable.
    
    Args:
        variable_id: ID of the variable to delete
        force: If true, deletes even if used by nodes
    """
    return await send_function_call("delete_variable", {
        "variable_id": variable_id,
        "force": force
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
    args = {}
    if name:
        args["name"] = name
    if color and color != "#4A90E2":
        args["color"] = color
    if tags:
        args["tags"] = tags
    if notes:
        args["notes"] = notes
    
    return await send_function_call("create_character", args)


@tool
async def update_character(
    character_id: int,
    name: str = None,
    color: str = None,
    tags: dict = None,
    notes: str = None
) -> str:
    """
    Update an existing character's properties.
    
    Args:
        character_id: ID of the character to update
        name: Optional new name
        color: Optional new color
        tags: Optional new tags (fully replaces existing)
        notes: Optional new notes
    """
    args = {"character_id": character_id}
    if name is not None and name != "":
        args["name"] = name
    if color is not None and color != "":
        args["color"] = color
    if tags is not None:
        args["tags"] = tags
    if notes is not None and notes != "":
        args["notes"] = notes
    
    return await send_function_call("update_character", args)


@tool
async def delete_character(
    character_id: int,
    force: bool = False
) -> str:
    """
    Delete a character.
    
    Args:
        character_id: ID of the character to delete
        force: If true, deletes even if used in dialog nodes
    """
    return await send_function_call("delete_character", {
        "character_id": character_id,
        "force": force
    })


# ========== Scene Tools ==========

@tool
async def create_scene(
    name: str,
    is_macro: bool = False,
    notes: str = ""
) -> str:
    """
    Create a new scene or macro.
    
    Args:
        name: Name of the scene
        is_macro: If true, creates a macro (reusable sub-graph)
        notes: Optional description/notes
    """
    args = {"is_macro": is_macro}
    if name:
        args["name"] = name
    if notes:
        args["notes"] = notes
    
    return await send_function_call("create_scene", args)


@tool
async def update_scene(
    scene_id: int,
    name: str = None,
    notes: str = None
) -> str:
    """
    Update scene properties.
    
    Args:
        scene_id: ID of the scene to update
        name: Optional new name
        notes: Optional new notes
    """
    args = {"scene_id": scene_id}
    if name is not None and name != "":
        args["name"] = name
    if notes is not None and notes != "":
        args["notes"] = notes
    
    return await send_function_call("update_scene", args)


@tool
async def delete_scene(
    scene_id: int,
    force: bool = False
) -> str:
    """
    Delete a scene and all its nodes.
    
    Args:
        scene_id: ID of the scene to delete
        force: If true, deletes even if referenced
    """
    return await send_function_call("delete_scene", {
        "scene_id": scene_id,
        "force": force
    })


@tool
async def set_scene_entry(
    node_id: int
) -> str:
    """
    Set the entry point for a scene.
    
    Args:
        node_id: ID of the node to set as scene entry
    """
    return await send_function_call("set_scene_entry", {
        "node_id": node_id
    })


@tool
async def set_project_entry(
    node_id: int
) -> str:
    """
    Set the main entry point for the entire project.
    
    Args:
        node_id: ID of the node to set as project entry
    """
    return await send_function_call("set_project_entry", {
        "node_id": node_id
    })


# ========== Context Query Tools ==========

@tool
async def get_nodes(node_type: str = None, character_id: int = None, scene_id: int = None) -> str:
    """
    Get nodes from the current Arrow file based on filters.
    
    Args:
        node_type: Optional type of node to filter by (dialog, content, condition, etc.)
        character_id: Optional character ID to filter dialog/monolog nodes by character
        scene_id: Optional scene ID to filter nodes from
        
    Returns:
        List of matching nodes with their data
        
    Examples:
        - get_nodes(node_type="dialog") - Get all dialog nodes
        - get_nodes(node_type="dialog", character_id=11) - Get dialog nodes for character ID 11
        - get_nodes(character_id=11) - Get all nodes (any type) for character ID 11
    """
    arrow_file = current_context.get("arrow_file")
    if not arrow_file:
        return "No Arrow file loaded in context"
        
    try:
        nodes = arrow_file.get("resources", {}).get("nodes", {})
        results = []
        
        for node_id, node_data in nodes.items():
            # Filter by node type
            if node_type and node_data.get("type") != node_type:
                continue
                
            # Filter by character if specified
            if character_id is not None:
                node_character = node_data.get("data", {}).get("character")
                if node_character != character_id:
                    continue
                    
            # Filter by scene if specified
            if scene_id is not None:
                # Find node in scene map
                scene_found = False
                for scene in arrow_file.get("resources", {}).get("scenes", {}).values():
                    if str(scene_id) == str(scene.get("id")) and str(node_id) in scene.get("map", {}):
                        scene_found = True
                        break
                if not scene_found:
                    continue
                    
            results.append({
                "id": node_id,
                "type": node_data.get("type"),
                "name": node_data.get("name"),
                "data": node_data.get("data", {}),
                "notes": node_data.get("notes", "")
            })
            
        
        return json.dumps(results, indent=2)
        
    except Exception as e:
        return f"Error retrieving nodes: {str(e)}"


@tool
async def get_character(character_id: int = None, character_name: str = None) -> str:
    """
    Get character information by ID or name.
    
    Args:
        character_id: ID of the character to retrieve
        character_name: Name of the character to retrieve
        
    Returns:
        Character data if found
    """
    arrow_file = current_context.get("arrow_file")
    if not arrow_file:
        return "No Arrow file loaded in context"
        
    try:
        characters = arrow_file.get("resources", {}).get("characters", {})
        
        # Search by ID
        if character_id is not None:
            char = characters.get(str(character_id))
            if char:
                return json.dumps(char, indent=2)
            return f"Character with ID {character_id} not found"
            
        # Search by name
        if character_name:
            for char in characters.values():
                if char.get("name") == character_name:
                    return json.dumps(char, indent=2)
            return f"Character named '{character_name}' not found"
            
        # Return all characters if no filters
        return json.dumps(characters, indent=2)
        
    except Exception as e:
        return f"Error retrieving character: {str(e)}"


@tool
async def get_variable(variable_id: int = None, variable_name: str = None) -> str:
    """
    Get variable information by ID or name.
    
    Args:
        variable_id: ID of the variable to retrieve
        variable_name: Name of the variable to retrieve
        
    Returns:
        Variable data if found
    """
    arrow_file = current_context.get("arrow_file")
    if not arrow_file:
        return "No Arrow file loaded in context"
        
    try:
        variables = arrow_file.get("resources", {}).get("variables", {})
        
        # Search by ID
        if variable_id is not None:
            var = variables.get(str(variable_id))
            if var:
                
                return json.dumps(var, indent=2)
            return f"Variable with ID {variable_id} not found"
            
        # Search by name
        if variable_name:
            for var in variables.values():
                if var.get("name") == variable_name:
                    
                    return json.dumps(var, indent=2)
            return f"Variable named '{variable_name}' not found"
            
        # Return all variables if no filters
        
        return json.dumps(variables, indent=2)
        
    except Exception as e:
        return f"Error retrieving variable: {str(e)}"


@tool
async def get_scene(scene_id: int = None, scene_name: str = None) -> str:
    """
    Get scene information by ID or name.
    
    Args:
        scene_id: ID of the scene to retrieve
        scene_name: Name of the scene to retrieve
        
    Returns:
        Scene data if found
    """
    arrow_file = current_context.get("arrow_file")
    if not arrow_file:
        return "No Arrow file loaded in context"
        
    try:
        scenes = arrow_file.get("resources", {}).get("scenes", {})
        
        # Search by ID
        if scene_id is not None:
            scene = scenes.get(str(scene_id))
            if scene:
                
                return json.dumps(scene, indent=2)
            return f"Scene with ID {scene_id} not found"
            
        # Search by name
        if scene_name:
            for scene in scenes.values():
                if scene.get("name") == scene_name:
                    
                    return json.dumps(scene, indent=2)
            return f"Scene named '{scene_name}' not found"
            
        # Return all scenes if no filters
        
        return json.dumps(scenes, indent=2)
        
    except Exception as e:
        return f"Error retrieving scene: {str(e)}"


@tool
async def get_node_connections(node_id: int) -> str:
    """
    Get all connections to/from a specific node.
    
    Args:
        node_id: ID of the node to get connections for
        
    Returns:
        List of connections with source and target nodes
    """
    arrow_file = current_context.get("arrow_file")
    if not arrow_file:
        return "No Arrow file loaded in context"
        
    try:
        connections = []
        
        # Search all scenes for connections involving this node
        for scene in arrow_file.get("resources", {}).get("scenes", {}).values():
            scene_map = scene.get("map", {})
            
            # Look for the node in this scene
            node_data = scene_map.get(str(node_id))
            if node_data:
                # Get outgoing connections
                for conn in node_data.get("io", []):
                    connections.append({
                        "from_node": conn[0],
                        "from_slot": conn[1],
                        "to_node": conn[2],
                        "to_slot": conn[3]
                    })
                    
                # Get incoming connections
                for other_node in scene_map.values():
                    for conn in other_node.get("io", []):
                        if conn[2] == node_id:
                            connections.append({
                                "from_node": conn[0],
                                "from_slot": conn[1],
                                "to_node": conn[2],
                                "to_slot": conn[3]
                            })
                            
        if not connections:
            return f"No connections found for node {node_id}"
            
        
        return json.dumps(connections, indent=2)
        
    except Exception as e:
        return f"Error retrieving connections: {str(e)}"


# List of all tools for the executor
ARROW_TOOLS = [
    # Node creation
    create_dialog_node,
    create_content_node,
    create_hub_node,
    create_condition_node,
    create_variable_update_node,
    # Node operations
    update_node,
    delete_node,
    # Connections
    create_connection,
    delete_connection,
    # Variables
    create_variable,
    update_variable,
    delete_variable,
    # Characters
    create_character,
    update_character,
    delete_character,
    # Scenes
    create_scene,
    update_scene,
    delete_scene,
    set_scene_entry,
    set_project_entry,
    # Context queries
    get_nodes,
    get_character,
    get_variable,
    get_scene,
    get_node_connections,
]

