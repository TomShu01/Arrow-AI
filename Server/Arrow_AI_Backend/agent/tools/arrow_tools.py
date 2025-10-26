"""
Arrow Tools - Technical implementation tools for narrative design operations
These tools send function calls via WebSocket to the Arrow client

===================================================================================
TECHNICAL IMPLEMENTATION REFERENCE
===================================================================================

This reference covers the technical details needed to implement the narrative
plans created by the planner. Focus: HOW to implement, not WHAT to create.

-----------------------------------------------------------------------------------
CRITICAL TECHNICAL RULES
-----------------------------------------------------------------------------------

1. ⚠️ EVERY NODE MUST BE CONNECTED - Disconnected nodes never execute!
2. ⚠️ CREATE RESOURCES BEFORE USE - Characters, variables must exist before referencing
3. ⚠️ CONNECTIONS REQUIRE BOTH NODES - Create both nodes before connecting them
4. ⚠️ TEXT INPUT REQUIRES VALIDATION - Never create user_input without pattern for text

-----------------------------------------------------------------------------------
CONNECTION SLOT NUMBERS (CRITICAL FOR BRANCHING)
-----------------------------------------------------------------------------------

Understanding slot numbers is essential for proper connections:

STANDARD NODES (single output):
- Content, Monolog, Entry, Marker, Jump, Variable Update, Tag Edit, User Input
- Always use: from_slot=0, to_slot=0

BRANCHING NODES (multiple outputs):
Dialog (with playable=true):
  - from_slot=0 → First line chosen
  - from_slot=1 → Second line chosen
  - from_slot=2 → Third line chosen, etc.

Interaction:
  - from_slot=0 → First action chosen
  - from_slot=1 → Second action chosen
  - from_slot=2 → Third action chosen, etc.

Condition:
  - from_slot=0 → TRUE branch (condition passed)
  - from_slot=1 → FALSE branch (condition failed)

Randomizer:
  - from_slot=0 → First random path
  - from_slot=1 → Second random path, etc.


-----------------------------------------------------------------------------------
USER INPUT VALIDATION PATTERNS (REGEX)
-----------------------------------------------------------------------------------

Text input ALWAYS needs validation! Common patterns:

Character name (3-12 letters):
  "^[a-zA-Z]{3,12}$"

Any word (minimum 1 character):
  "^[\w]{1,}$"

Yes/No (case-insensitive):
  "(?i)^(yes|no)$"

Specific puzzle answers (case-insensitive):
  "(?i)^(tree|mountain|forest)$"

Email format:
  "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

Number as text (for puzzles):
  "^[0-9]+$"

REGEX SYNTAX NOTES:
- ^ = start of string
- $ = end of string
- (?i) = case-insensitive
- {3,12} = length between 3 and 12
- {1,} = minimum 1, no maximum
- | = OR operator
- [...] = character class
- \w = word character (alphanumeric + underscore)

-----------------------------------------------------------------------------------
RESOURCE CREATION ORDER
-----------------------------------------------------------------------------------

Always create in this order:
1. Characters (before using in dialog/monolog/tag nodes)
2. Variables (before using in conditions/updates/user-input)
3. Scenes (if organizing into chapters)
4. Nodes (after characters and variables exist)
5. Connections (after both nodes exist)

-----------------------------------------------------------------------------------
VARIABLE TYPES & OPERATIONS
-----------------------------------------------------------------------------------

VARIABLE TYPES:
- "num": Numbers (health, score, stats) - operations: set, add, subtract, multiply, divide
- "str": Text (names, answers, items) - operations: set only
- "bool": True/False flags - operations: set only

NAMING BEST PRACTICES:
- player_health, hero_karma, enemy_count (descriptive)
- has_key, is_alive, knows_secret (boolean prefixes)
- Use underscores, not camelCase

-----------------------------------------------------------------------------------
CHARACTER TAG OPERATIONS
-----------------------------------------------------------------------------------

Tag Edit Operations:
- "inset": Add key:value only if key doesn't exist
- "reset": Update value only if key exists
- "overset": Add or update key:value (most common)
- "outset": Remove tag only if both key and value match
- "unset": Remove tag by key (ignore value)

Common tag uses:
- Items: "has_sword": "iron", "gold": "150"
- Flags: "killed_dragon": "true", "visited_town": "true"
- Relationships: "trust_level": "5", "faction": "rebels"

-----------------------------------------------------------------------------------
MARKER COLOR CONVENTIONS
-----------------------------------------------------------------------------------

Hex format: #RRGGBBAA (with alpha channel)

Common conventions:
- #007FFFFF (Cyan) - Scene setup/description markers
- #00FFFFFF (Transparent white) - Animation hooks (labels with *)
- #FF0000FF (Red) - TODO/WIP markers
- #00FF00FF (Green) - Completed/tested sections
- #FFFF00FF (Yellow) - Important notes

Animation hook pattern: Label starting with * or !
Example: "*[character_reveal]", "*[door_opens]"

===================================================================================
END OF TECHNICAL REFERENCE
===================================================================================
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
    
    Returns error messages as strings instead of raising exceptions, so the agent
    can see errors and use tools to fix them autonomously.
    """
    session_id = current_context.get("session_id")
    if not session_id:
        return "ERROR: No session context set. Cannot execute function call."
    
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
        # Return error as string so agent can see it and potentially retry
        return f"ERROR: Timeout waiting for function result: {function_name}. The client may be unresponsive."
    except Exception as e:
        pending_calls.pop(request_id, None)
        # Return error as string so agent can analyze and fix the issue
        error_msg = str(e)
        return f"ERROR executing {function_name}: {error_msg}. Analyze the error and use tools to fix it."


# ========== Node Creation Tools ==========

@tool
async def create_dialog_node(
    character_id: int,
    lines: list[str],
    playable: bool = True,
    name: str = "",
    scene_id: int = None
) -> str:
    """
    Create a dialog node with character speech.
    
    Technical details:
    - Multiple lines → each line gets its own output slot (0, 1, 2...)
    - playable=True → player chooses which line (branching)
    - playable=False → random line is chosen (no branching)
    
    Args:
        character_id: ID of the character speaking (-1 for anonymous)
        lines: List of dialog lines to display
        playable: If true, player chooses line (default: True)
        name: Optional custom name for the node
        scene_id: Scene to create in (defaults to current scene)
    
    Output slots (if playable=True):
        lines[0] → from_slot=0
        lines[1] → from_slot=1
        lines[2] → from_slot=2, etc.
    """
    return await send_function_call("create_insert_node", {
        "type": "dialog",
        "name": name,
        "scene_id": scene_id or current_context.get("scene_id"),
        "preset": {
            "data": {
                "character": character_id,
                "lines": lines,
                "playable": playable
            }
        }
    })


@tool
async def create_content_node(
    title: str,
    content: str,
    name: str = "",
    auto_play: bool = False,
    clear: bool = False,
    scene_id: int = None
) -> str:
    """
    Create a content node to display narrative text (not tied to a character).
    
    Technical details:
    - Single output slot (from_slot=0)
    - Supports BBCode formatting
    - Supports variable substitution: {variable_name}
    
    Args:
        title: Title of the content
        content: Main text content to display
        name: Optional custom name for the node
        auto_play: If true, auto-advances without player input (default: False)
        clear: If true, clears previous content (default: False)
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
                "clear": clear
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
    
    Technical details:
    - Two output slots based on comparison result
    - from_slot=0 → TRUE branch (condition passed)
    - from_slot=1 → FALSE branch (condition failed)
    - Operators: ==, !=, >, <, >=, <=
    
    Args:
        variable_id: ID of the variable to check
        operator: Comparison operator (==, !=, >, <, >=, <=)
        compare_value: Value to compare against (must match variable type)
        name: Optional custom name for the node
        scene_id: Scene to create in (defaults to current scene)
    
    Example:
        # Check if health < 20
        condition_id = await create_condition_node(health_var_id, "<", 20)
        await create_connection(condition_id, game_over_node, from_slot=0)  # TRUE
        await create_connection(condition_id, continue_node, from_slot=1)   # FALSE
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
    
    Technical details:
    - Single output slot (from_slot=0)
    - Operations for num: set, add, subtract, multiply, divide
    - Operations for str/bool: set only
    
    Args:
        variable_id: ID of the variable to update
        operation: Operation to perform (set, add, subtract, multiply, divide)
        value: Value to use in the operation
        name: Optional custom name for the node
        scene_id: Scene to create in (defaults to current scene)
    
    Common usage: Chain after player choices to track consequences.
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


@tool
async def create_user_input_node(
    prompt: str,
    variable_id: int,
    input_type: Literal["text", "number", "bool"] = "text",
    pattern: str = None,
    min_value: int = None,
    max_value: int = None,
    step: int = None,
    default_value: str | int | bool = None,
    name: str = "",
    scene_id: int = None
) -> str:
    """
    Create a user input node to get direct input from the player.
    
    Technical details:
    - Single output slot (from_slot=0)
    - CRITICAL: Text input REQUIRES validation pattern (raises error if missing)
    - Stores input in the specified variable
    - Player cannot proceed without valid input
    
    Args:
        prompt: Question/prompt to show the player
        variable_id: ID of variable to store the input
        input_type: Type of input - "text", "number", or "bool"
        pattern: For text - regex validation pattern (REQUIRED!)
        min_value: For number - minimum allowed value
        max_value: For number - maximum allowed value
        step: For number - step increment
        default_value: Default/preset value
        name: Optional custom name for the node
        scene_id: Scene to create in (defaults to current scene)
    
    See system prompt for common regex patterns and examples.
    """
    # Build custom settings based on input type
    custom_settings = {}
    
    if input_type == "text":
        if pattern is None:
            raise ValueError("Text input REQUIRES a validation pattern! Provide a regex pattern to validate input.")
        custom_settings["pattern"] = pattern
        if default_value is not None:
            custom_settings["default"] = default_value
            
    elif input_type == "number":
        if min_value is not None:
            custom_settings["min"] = min_value
        if max_value is not None:
            custom_settings["max"] = max_value
        if step is not None:
            custom_settings["step"] = step
        if default_value is not None:
            custom_settings["value"] = default_value
            
    elif input_type == "bool":
        if default_value is not None:
            custom_settings["preset_state"] = default_value
    
    return await send_function_call("create_insert_node", {
        "type": "user_input",
        "name": name,
        "scene_id": scene_id or current_context.get("scene_id"),
        "preset": {
            "data": {
                "prompt": prompt,
                "variable": variable_id,
                "custom": custom_settings
            }
        }
    })


@tool
async def create_monolog_node(
    character_id: int,
    monolog: str,
    auto: bool = False,
    clear: bool = False,
    name: str = "",
    scene_id: int = None
) -> str:
    """
    Create a monolog node for single long character speech or thoughts.
    
    Technical details:
    - Single output slot (from_slot=0) - no branching
    - Supports BBCode formatting and variable substitution
    - For long speeches or thoughts, not choices
    
    Args:
        character_id: ID of the character speaking (-1 for anonymous)
        monolog: The text content
        auto: If true, auto-advances without waiting (default: False)
        clear: If true, clears previous content (default: False)
        name: Optional custom name for the node
        scene_id: Scene to create in (defaults to current scene)
    """
    return await send_function_call("create_insert_node", {
        "type": "monolog",
        "name": name,
        "scene_id": scene_id or current_context.get("scene_id"),
        "preset": {
            "data": {
                "character": character_id,
                "monolog": monolog,
                "brief": -1,
                "auto": auto,
                "clear": clear
            }
        }
    })


@tool
async def create_interaction_node(
    actions: list[str],
    name: str = "",
    scene_id: int = None
) -> str:
    """
    Create an interaction node for action-based choices (not dialog).
    
    Technical details:
    - Multiple output slots, one per action
    - actions[0] → from_slot=0, actions[1] → from_slot=1, etc.
    - Waits for player to choose action
    - Use for non-conversation actions (not character speech)
    
    Args:
        actions: List of action descriptions presented to player
        name: Optional custom name for the node
        scene_id: Scene to create in (defaults to current scene)
    """
    return await send_function_call("create_insert_node", {
        "type": "interaction",
        "name": name,
        "scene_id": scene_id or current_context.get("scene_id"),
        "preset": {
            "data": {
                "actions": actions
            }
        }
    })


@tool
async def create_marker_node(
    label: str,
    color: str = "#00FFFFFF",
    name: str = "",
    scene_id: int = None
) -> str:
    """
    Create a marker node for visual labels or animation hooks.
    
    Technical details:
    - Single output slot (from_slot=0)
    - Labels starting with * often used as runtime hooks
    - Color format: #RRGGBBAA (hex with alpha)
    
    Args:
        label: Text label for the marker
        color: Hex color with alpha (default: #00FFFFFF - transparent white)
        name: Optional custom name for the node
        scene_id: Scene to create in (defaults to current scene)
    
    See system prompt for color conventions.
    """
    return await send_function_call("create_insert_node", {
        "type": "marker",
        "name": name,
        "scene_id": scene_id or current_context.get("scene_id"),
        "preset": {
            "data": {
                "label": label,
                "color": color
            }
        }
    })


@tool
async def create_jump_node(
    target_node_id: int,
    reason: str = "",
    name: str = "",
    scene_id: int = None
) -> str:
    """
    Create a jump node to navigate to distant nodes or different scenes.
    
    Technical details:
    - No output slot (jumps directly to target)
    - target_node_id=-1 means end of story (EOL)
    - Use instead of long connection lines
    
    Args:
        target_node_id: ID of the node to jump to (-1 for end/EOL)
        reason: Description displayed on node (optional)
        name: Optional custom name for the node
        scene_id: Scene to create in (defaults to current scene)
    """
    return await send_function_call("create_insert_node", {
        "type": "jump",
        "name": name,
        "scene_id": scene_id or current_context.get("scene_id"),
        "preset": {
            "data": {
                "target": target_node_id,
                "reason": reason
            }
        }
    })


@tool
async def create_tag_edit_node(
    character_id: int,
    edit_operation: Literal["inset", "reset", "overset", "outset", "unset"],
    tag_key: str,
    tag_value: str = "",
    name: str = "",
    scene_id: int = None
) -> str:
    """
    Create a tag edit node to modify character tags dynamically.
    
    Technical details:
    - Single output slot (from_slot=0)
    - Tags are key-value pairs on characters
    - More dynamic than variables (can create at runtime)
    
    Args:
        character_id: ID of the character whose tags to modify
        edit_operation: Type of edit
            - "overset": Add or update (most common)
            - "inset": Add only if doesn't exist
            - "reset": Update only if exists
            - "unset": Remove by key
            - "outset": Remove by key+value match
        tag_key: Tag key (e.g., "has_key", "knows_secret")
        tag_value: Tag value (e.g., "true", "iron_sword")
        name: Optional custom name for the node
        scene_id: Scene to create in (defaults to current scene)
    
    See system prompt for tag operation details.
    """
    return await send_function_call("create_insert_node", {
        "type": "tag_edit",
        "name": name,
        "scene_id": scene_id or current_context.get("scene_id"),
        "preset": {
            "data": {
                "character": character_id,
                "edit": [
                    0 if edit_operation == "inset" else
                    1 if edit_operation == "reset" else
                    2 if edit_operation == "overset" else
                    3 if edit_operation == "outset" else
                    4,  # unset
                    tag_key,
                    tag_value
                ]
            }
        }
    })


@tool
async def create_randomizer_node(
    num_paths: int,
    name: str = "",
    scene_id: int = None
) -> str:
    """
    Create a randomizer node for random path selection.
    
    Technical details:
    - Multiple output slots: 0, 1, 2, ... (num_paths-1)
    - Randomly chooses ONE slot each time played
    - Adds variance and replayability
    
    Args:
        num_paths: Number of random output paths (minimum 2)
        name: Optional custom name for the node
        scene_id: Scene to create in (defaults to current scene)
    """
    if num_paths < 2:
        raise ValueError("Randomizer must have at least 2 paths")
        
    return await send_function_call("create_insert_node", {
        "type": "randomizer",
        "name": name,
        "scene_id": scene_id or current_context.get("scene_id"),
        "preset": {
            "data": {
                "slots": num_paths
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
    connections is orphaned and will never execute in the narrative.
    
    This tool:
    1. Adds the connection to the Arrow project data
    2. Queues the connection for visual rendering on the graph
    3. Updates both nodes to reflect the connection
    
    Args:
        from_node_id: ID of the source node (where the arrow starts)
        to_node_id: ID of the target node (where the arrow points to)
        from_slot: Output slot on source node (default: 0)
                   - Most nodes: always use 0
                   - Dialog/Interaction nodes: 0 = first choice, 1 = second choice, 2 = third choice, etc.
                   - Condition nodes: 0 = true branch, 1 = false branch
                   - Randomizer nodes: 0 = first path, 1 = second path, etc.
        to_slot: Input slot on target node (default: 0, rarely needs to change)
    
    Returns:
        Success message with connection details.
    
    Examples:
        # Simple linear connection (most common)
        await create_connection(from_node_id=2, to_node_id=4)
        
        # Dialog/Interaction with 3 choices connecting to different nodes
        await create_connection(from_node_id=5, to_node_id=10, from_slot=0)  # Choice 1
        await create_connection(from_node_id=5, to_node_id=11, from_slot=1)  # Choice 2
        await create_connection(from_node_id=5, to_node_id=12, from_slot=2)  # Choice 3
        
        # Branches continuing to next part of story
        await create_connection(from_node_id=10, to_node_id=20)  # Branch 1 → Continue
        await create_connection(from_node_id=11, to_node_id=20)  # Branch 2 → Continue
        await create_connection(from_node_id=12, to_node_id=20)  # Branch 3 → Continue
        
        # Condition with true/false branches
        await create_connection(from_node_id=8, to_node_id=20, from_slot=0)  # True
        await create_connection(from_node_id=8, to_node_id=21, from_slot=1)  # False
    """
    # Use update_node_map to add connection (it handles both data and visual drawing)
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
    # Core narrative node creation
    create_dialog_node,
    create_content_node,
    create_monolog_node,
    
    # Choice/branching node creation
    create_interaction_node,
    create_condition_node,
    create_randomizer_node,
    
    # State management node creation
    create_variable_update_node,
    create_user_input_node,
    create_tag_edit_node,
    
    # Navigation node creation
    create_jump_node,
    create_marker_node,
    
    # Node operations
    update_node,
    delete_node,
    
    # Connections (CRITICAL - nodes must be connected!)
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

