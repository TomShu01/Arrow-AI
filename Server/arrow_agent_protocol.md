# Arrow AI Agent - WebSocket Protocol & Tool Calling Specification

## Overview

This document specifies a WebSocket-based protocol for an AI agent to interact with Arrow narrative design tool. The protocol simplifies Arrow's internal functions to make them more suitable for LLM-based agents.

## Architecture

```
Client (Arrow Editor) <--WebSocket--> Server (AI Agent + PDF Processing)
```

### Client Responsibilities

- Send `.arrow` file content when changed
- Send user messages/requests
- Execute function calls received from agent
- Send stop/error signals
- Upload PDF files for context

### Server Responsibilities

- Maintain synchronized state of `.arrow` file
- Process user messages with LLM
- Store and process PDF narratives (RAG)
- Send chat responses or function calls
- Handle stop signals

---

## Message Protocol

All messages are JSON objects with a `type` field.

### Client → Server Messages

#### 1. File Sync Message

```json
{
  "type": "file_sync",
  "project_id": 1,
  "arrow_content": "<complete .arrow file content as string>",
  "timestamp": 1698765432
}
```

#### 2. Design doc sync [Later]

```json
{
  "type": "design_doc_sync",
  "project_id": 1,
  "file_content": "base 64 pdf",
  "file_name": "",
  "timestamp": 1698765432
}
```

---

#### 3. User Message

```json
{
  "type": "user_message",
  "message": "Add a dialog node where the protagonist asks about the ancient artifact",
  "history": [
    { "message": "x1", "output": "y1" },
    { "message": "x2", "output": "y2" }
  ],
  "selected_node_ids": [12, 15],
  "current_scene_id": 5,
  "current_project_id": 1
}
```

#### 4. Function Result

```json
{
  "type": "function_result",
  "request_id": "req_12345",
  "success": true,
  "result": "Node created successfully",
  "error": ""
}
```

Or on error:

```json
{
  "type": "function_result",
  "request_id": "req_12345",
  "success": false,
  "result": "",
  "error": "Node type 'invalid_type' does not exist"
}
```

---

#### 5. Stop Signal

```json
{
  "type": "stop"
}
```

---

### Server → Client Messages

#### 1. Chat Response

```json
{
  "type": "chat_response",
  "message": "I've analyzed your request. I'll create a dialog node and connect it to the current flow."
}
```

---

#### 2. Function Call

```json
{
  "type": "function_call",
  "request_id": "req_12345",
  "function": "create_node",
  "arguments": {
    "type": "dialog",
    "position": "auto",
    "data": {
      "character_id": 3,
      "lines": [
        "Tell me about this ancient artifact.",
        "What do you know about its origins?"
      ]
    }
  }
}
```

#### 3. End message

```json
{
  "type": "end"
}
```

## Simplified Function Calls

Below are the simplified function calls designed for LLM agents. Complex parameters like `offset` (Vector2), `preset` (Dictionary), and manual ID management are abstracted away.

### Node Operations

#### 1. `create_insert_node`

```gdscript
func create_insert_node(type: String, offset: Vector2, scene_id: int = -1, draw: bool = true, name_prefix: String = "", preset: Dictionary = {}) -> int
```

Client should default the offset vector to 0, 0

**Simplified Arguments:**

```json
{
  "type": "dialog | content | condition | hub | interaction | jump | entry | frame | generator | randomizer | sequencer | marker | monolog | tag_edit | tag_match | tag_pass | user_input | variable_update | macro_use",

  "name": "optional_custom_name",

  "preset": {
    // Node-specific data structure (see Node Data Structures section)
  },
  "scene_id": 5
}
```

**Simplifications:**

- `data` is a simple dictionary rather than a complex `preset`
- `connect_from` automatically handles connection creation
- Automatic name generation if `name` not provided

---

#### 2. `update_node_map`

**Purpose:** Update node connections in the scene map. This is required for managing connections since `create_node` and `update_node` cannot modify connection data.

**Arrow Background:** Connections between nodes are stored in the scene map as an array of connection definitions `[from_id, from_slot, to_id, to_slot]`. This function allows adding or removing connections after node creation.

**Original Arrow Function:**

```gdscript
func update_node_map(node_id: int, modification: Dictionary, scene_id: int = -1) -> void
```

**Simplified Arguments:**

```json
{
  "node_id": 42, // or "last_created" or "selected"
  "scene_id": 5, // optional, defaults to current scene

  "modifications": {
    "io": {
      "push": [
        [from_id, from_slot, to_id, to_slot],
        [from_id2, from_slot2, to_id2, to_slot2]
      ],
      "pop": [
        [from_id, from_slot, to_id, to_slot]
      ]
    }
  }
}
```

---

#### 3. `update_node`

**Purpose:** Update an existing node's properties or data.

**Arrow Background:** Nodes have core properties (name, notes) and type-specific data. The data structure varies by node type. For example, a dialog node has character and lines, while a condition node has variable and comparison operator.

**Original Arrow Function:**

```gdscript
func update_node(node_id: int, name: String = "", data: Dictionary = {}, notes: String = "", is_auto_update: bool = false) -> void
```

**Simplified Arguments:**

```json
{
  "node_id": 42, // or "last_created" or "selected"

  "name": "optional_new_name",

  "data": {
    // Partial update - only include fields you want to change
    // Merged with existing data
  },

  "notes": "Optional development notes"
}
```

**Returns:**

```json
{
  "success": true
}
```

**Simplifications:**

- Can reference nodes by special keywords: `"last_created"`, `"selected"`, `"first_selected"`
- Partial data updates - only specify what changes
- No need to handle `is_auto_update` flag

---

#### 4. `delete_node`

**Purpose:** Remove a node from the scene.

**Arrow Background:** Removing nodes is complex because Arrow tracks dependencies. A node being used by others (as a jump target, macro reference, etc.) cannot be deleted. The system maintains a reference graph.

**Original Arrow Function:**

```gdscript
func remove_node(node_id: int, forced: bool = false) -> bool
```

**Simplified Arguments:**

```json
{
  "node_id": 42, // or "last_created" or "selected"
  "force": false // if true, breaks references
}
```

**Returns:**

```json
{
  "success": true,
  "removed_id": 42
}
```

Or if it cannot be removed:

```json
{
  "success": false,
  "error": "Node is referenced by other nodes",
  "referenced_by": [15, 16, 18]
}
```

**Simplifications:**

- Single boolean `force` instead of complex dependency checking
- Clear error messages with referencing nodes listed

---

#### 5. `create_connection`

**Purpose:** Connect two nodes to create narrative flow.

**Arrow Background:** Nodes connect via output slots (on the right) to input slots (on the left). Some nodes have multiple output slots (like hub for branching, condition for true/false paths). Connections form a directed graph representing narrative flow. Connections are stored in the scene map as arrays: `[from_id, from_slot, to_id, to_slot]`.

**CRITICAL:** Connections are both saved to the data AND drawn on the visual graph editor. Without creating connections, nodes are orphaned and won't execute in the narrative.

**Original Arrow Function:**

```gdscript
func update_node_map(node_id: int, modification: Dictionary, scene_id: int = -1) -> void
// with modification = { "io": { "push": [[from_id, from_slot, to_id, to_slot]] } }
```

**Tool Arguments:**

```json
{
  "from_node_id": 12, // Source node ID
  "to_node_id": 15, // Target node ID
  "from_slot": 0, // Optional: output slot on source (default: 0)
  "to_slot": 0 // Optional: input slot on target (default: 0)
}
```

**Returns:**

```json
{
  "success": true,
  "message": "Connection created from node 12 to node 15"
}
```

**Examples:**

```json
// Simple connection (most common)
{
  "from_node_id": 2,
  "to_node_id": 4
}

// Hub node with multiple choices
// Choice 1 (slot 0) goes to node 10
{
  "from_node_id": 5,
  "to_node_id": 10,
  "from_slot": 0
}
// Choice 2 (slot 1) goes to node 11
{
  "from_node_id": 5,
  "to_node_id": 11,
  "from_slot": 1
}
// Choice 3 (slot 2) goes to node 12
{
  "from_node_id": 5,
  "to_node_id": 12,
  "from_slot": 2
}

// Condition node with true/false branches
// True branch (slot 0) goes to node 20
{
  "from_node_id": 8,
  "to_node_id": 20,
  "from_slot": 0
}
// False branch (slot 1) goes to node 21
{
  "from_node_id": 8,
  "to_node_id": 21,
  "from_slot": 1
}
```

**Usage Notes:**

- Most connections use slot 0 for both sides (simple linear flow)
- Hub nodes have multiple output slots (one per choice): slot 0, 1, 2, etc.
- Condition nodes have 2 output slots: 0 = true branch, 1 = false branch
- Always create connections AFTER creating both nodes
- The tool internally calls `update_node_map` with the proper `io.push` structure
- Connections are queued and drawn after nodes are rendered to avoid timing issues

---

#### 6. `delete_connection`

**Purpose:** Remove a connection between two nodes.

**Arrow Background:** Connections must be removed from the scene map's IO array.

**Original Arrow Function:**

```gdscript
func update_node_map(node_id: int, modification: Dictionary, scene_id: int = -1) -> void
// with modification = { "io": { "pop": [[from_id, from_slot, to_id, to_slot]] } }
```

**Simplified Arguments:**

```json
{
  "from": 12,
  "from_slot": 0,
  "to": 15,
  "to_slot": 0
}
```

**Returns:**

```json
{
  "success": true
}
```

---

### Scene Operations

#### 7. `create_scene`

**Purpose:** Create a new scene or macro.

**Arrow Background:** Arrow projects are organized into scenes (narrative chapters/sections) and macros (reusable sub-graphs). Each scene has its own canvas with nodes and an entry point. Macros are scenes marked with a special flag and cannot be project entry points.

**Original Arrow Function:**

```gdscript
func create_new_scene(is_macro: bool = false) -> void
```

**Simplified Arguments:**

```json
{
  "name": "Chapter 2: The Journey",
  "is_macro": false,
  "notes": "Optional scene description"
}
```

**Returns:**

```json
{
  "scene_id": 8,
  "entry_node_id": 50
}
```

**Simplifications:**

- Specify name directly instead of auto-generation
- Automatically creates entry node
- Returns both scene ID and entry node ID

---

#### 8. `update_scene`

**Purpose:** Update scene properties.

**Arrow Background:** Scenes have a name, entry point node, macro flag, and notes.

**Original Arrow Function:**

```gdscript
func update_scene(scene_id: int, name: String = "", entry: int = -1, macro: bool = null, notes: String = "") -> void
```

**Simplified Arguments:**

```json
{
  "scene_id": 8, // or "current"
  "name": "New Scene Name",
  "notes": "Updated description"
}
```

**Returns:**

```json
{
  "success": true
}
```

**Simplifications:**

- Entry point management is handled by `set_scene_entry` function
- Cannot change macro flag after creation (structural constraint)
- `"current"` refers to currently open scene

---

#### 9. `delete_scene`

**Purpose:** Remove a scene and all its nodes.

**Arrow Background:** Deleting a scene removes all nodes within it. This is a destructive operation with dependency checking.

**Original Arrow Function:**

```gdscript
func remove_scene(scene_id: int, forced: bool = false) -> bool
```

**Simplified Arguments:**

```json
{
  "scene_id": 8,
  "force": false
}
```

**Returns:**

```json
{
  "success": true,
  "removed_nodes": [50, 51, 52, 53]
}
```

**Simplifications:**

- Returns list of removed nodes
- Prevents removing scene with project entry point

---

#### 10. `set_scene_entry`

**Purpose:** Set which node is the entry point for a scene.

**Arrow Background:** Each scene must have one entry node where playback begins. This is typically an Entry-type node but can be any node.

**Original Arrow Function:**

```gdscript
func update_scene_entry(node_id: int) -> int
```

**Simplified Arguments:**

```json
{
  "node_id": 42
}
```

**Returns:**

```json
{
  "success": true,
  "previous_entry": 38
}
```

---

#### 11. `set_project_entry`

**Purpose:** Set which node is the main entry point for the entire project.

**Arrow Background:** The project has one global entry point where the narrative begins when played. This must be in a regular scene (not a macro).

**Original Arrow Function:**

```gdscript
func update_project_entry(node_id: int) -> int
```

**Simplified Arguments:**

```json
{
  "node_id": 42
}
```

**Returns:**

```json
{
  "success": true,
  "previous_entry": 12
}
```

---

### Variable Operations

#### 12. `create_variable`

**Purpose:** Create a global variable.

**Arrow Background:** Variables in Arrow are global state containers typed as string, number, or boolean. They're used by nodes like Condition, Variable Update, and Generator. Variables have an initial value and can be referenced by nodes.

**Original Arrow Function:**

```gdscript
func create_new_variable(type: String) -> void
```

**Simplified Arguments:**

```json
{
  "name": "player_health",
  "type": "num | str | bool",
  "initial_value": 100,
  "notes": "Player's current health points"
}
```

**Returns:**

```json
{
  "variable_id": 7
}
```

**Simplifications:**

- Specify name and initial value in one call
- No separate update needed
- Type validation happens automatically

---

#### 13. `update_variable`

**Purpose:** Update variable properties.

**Arrow Background:** Variables can have their name, type (with conversion), initial value, and notes modified. Renaming a variable updates all references automatically.

**Original Arrow Function:**

```gdscript
func update_variable(variable_id: int, name: String = "", type: String = "", initial_value = null, notes: String = "") -> void
```

**Simplified Arguments:**

```json
{
  "variable_id": 7, // or "by_name": "player_health"
  "name": "new_name",
  "initial_value": 150,
  "notes": "Updated description"
}
```

**Returns:**

```json
{
  "success": true
}
```

**Simplifications:**

- Can reference by name instead of ID with `"by_name"` field
- Type changes discouraged (structural issue)
- Auto-updates all referencing nodes

---

#### 14. `delete_variable`

**Purpose:** Remove a variable.

**Arrow Background:** Variables used by nodes cannot be deleted without forcing.

**Original Arrow Function:**

```gdscript
func remove_variable(variable_id: int, forced: bool = false) -> bool
```

**Simplified Arguments:**

```json
{
  "variable_id": 7, // or "by_name": "player_health"
  "force": false
}
```

**Returns:**

```json
{
  "success": true
}
```

Or:

```json
{
  "success": false,
  "error": "Variable is used by nodes",
  "used_by": [12, 15, 18]
}
```

---

### Character Operations

#### 15. `create_character`

**Purpose:** Create a character entity.

**Arrow Background:** Characters in Arrow represent speakers in dialogs and entities for tag-based systems. Each character has a name, display color, and optional tags (key-value metadata).

**Original Arrow Function:**

```gdscript
func create_new_character() -> void
```

**Simplified Arguments:**

```json
{
  "name": "Elena the Scholar",
  "color": "#4A90E2",
  "tags": {
    "faction": "Academy",
    "knows_secret": "true"
  },
  "notes": "Wise mentor character"
}
```

**Returns:**

```json
{
  "character_id": 4
}
```

**Simplifications:**

- All properties in one call
- Color as hex string instead of internal format
- Tags as simple key-value object

---

#### 16. `update_character`

**Purpose:** Update character properties.

**Arrow Background:** Character name changes update all dialog nodes automatically. Tags can be added/modified/removed.

**Original Arrow Function:**

```gdscript
func update_character(character_id: int, name: String = "", color: String = "", tags: Dictionary = {}, notes: String = "") -> void
```

**Simplified Arguments:**

```json
{
  "character_id": 4, // or "by_name": "Elena the Scholar"
  "name": "Elena the Wise",
  "color": "#5A9FE2",
  "tags": {
    "faction": "Academy",
    "knows_secret": "true",
    "trust_level": "5"
  },
  "notes": "Updated character"
}
```

**Returns:**

```json
{
  "success": true
}
```

**Simplifications:**

- Can reference by name
- Tags are fully replaced (not merged) for simplicity
- Color validation

---

#### 17. `delete_character`

**Purpose:** Remove a character.

**Arrow Background:** Characters used in dialog/monolog nodes cannot be deleted.

**Original Arrow Function:**

```gdscript
func remove_character(character_id: int, forced: bool = false) -> bool
```

**Simplified Arguments:**

```json
{
  "character_id": 4, // or "by_name": "Elena the Scholar"
  "force": false
}
```

**Returns:**

```json
{
  "success": true
}
```

---

## Node Type Data Structures

Below are the simplified data structures for each node type's `data` field:

### 1. Content

Display text content to the player.

```json
{
  "title": "Chapter Title",
  "content": "The main text content that will be displayed...",
  "brief": 50, // Characters to show as preview
  "auto_play": false, // Auto-advance to next
  "clear": false // Clear previous content
}
```

---

### 2. Dialog

Character dialogue with multiple lines.

```json
{
  "character": 3, // character_id or -1 for anonymous
  "lines": ["First line of dialog", "Second line", "Third line"],
  "playable": true // All lines shown or player chooses
}
```

---

### 3. Monolog

Single character line (simplified dialog).

```json
{
  "character": 3,
  "text": "A single line of dialog"
}
```

---

### 4. Condition

Branch based on variable comparison.

```json
{
  "variable": 7, // variable_id
  "operator": "== | != | > | < | >= | <=",
  "compare_to": {
    "type": "value | variable",
    "value": 100 // or variable_id if type is "variable"
  }
  // Two output slots: 0 = true, 1 = false
}
```

---

### 5. Hub

Multiple choice branching.

```json
{
  "options": ["Option 1 text", "Option 2 text", "Option 3 text"]
  // Each option gets an output slot (0, 1, 2, ...)
}
```

---

### 6. Interaction

Interactive choices (like hub but with different semantics).

```json
{
  "actions": ["Look around", "Talk to merchant", "Leave town"]
  // Each action gets an output slot
}
```

---

### 7. Variable Update

Modify a variable's value.

```json
{
  "variable": 7, // variable_id
  "operation": "set | add | subtract | multiply | divide",
  "value": {
    "type": "value | variable",
    "value": 10 // or variable_id
  }
}
```

---

### 8. Jump

Jump to another node/scene.

```json
{
  "target": {
    "type": "node | scene | marker",
    "id": 42 // node_id or scene_id or marker_id
  }
}
```

---

### 9. Marker

Named marker for jumps.

```json
{
  "label": "checkpoint_1"
}
```

---

### 10. Randomizer

Random branching.

```json
{
  "paths": 3, // Number of output paths
  "weights": [1, 2, 1] // Optional weights (equal if omitted)
}
```

---

### 11. Sequencer

Cycles through outputs sequentially.

```json
{
  "paths": 4, // Number of output paths
  "reset": true // Reset to 0 after last path
}
```

---

### 12. Generator

Generate random values.

```json
{
  "variable": 7, // variable to store result
  "generator_type": "random_int | random_bool | dice",
  "min": 1, // for random_int
  "max": 100,
  "dice": "2d6+3" // for dice type
}
```

---

### 13. Tag Edit

Modify character tags.

```json
{
  "character": 3,
  "operations": [
    { "action": "set | remove", "key": "faction", "value": "Rebels" },
    { "action": "set", "key": "trust_level", "value": "5" }
  ]
}
```

---

### 14. Tag Match

Branch based on character tags.

```json
{
  "character": 3,
  "match": {
    "type": "has_key | equals | not_equals",
    "key": "faction",
    "value": "Academy" // omit for has_key
  }
  // Output slots: 0 = match, 1 = no match
}
```

---

### 15. Tag Pass

Check multiple tag conditions.

```json
{
  "character": 3,
  "method": "any | all", // any condition matches or all must match
  "conditions": [
    { "key": "faction", "value": "Academy" },
    { "key": "trust_level", "value": "5" }
  ]
  // Output slots: 0 = pass, 1 = fail
}
```

---

### 16. User Input

Prompt user for input.

```json
{
  "prompt": "Enter your character name:",
  "variable": 2, // variable_id to store result
  "input_type": "text | number"
}
```

---

### 17. Macro Use

Call a macro (reusable scene).

```json
{
  "macro": 15 // scene_id of macro
}
```

---

### 18. Entry

Scene entry point (usually created automatically).

```json
{
  "label": "Start"
}
```

---

### 19. Frame

Visual grouping container (no logic).

```json
{
  "title": "Combat System",
  "color": "#FF5733"
}
```

---

## Special Node References

Throughout the API, these keywords can be used instead of numeric IDs:

- `"last_created"`: The most recently created node
- `"last_selected"`: The last node the user selected
- `"selected"`: Currently selected node (error if multiple)
- `"first_selected"`: First of currently selected nodes
- `"current_entry"`: Current scene's entry node
- `"project_entry"`: Project's main entry node

---

## Example Conversation Flow

### User Request:

"Create a dialog where the protagonist meets Elena and she offers to help, then add a choice for the player to accept or refuse."

### Agent Response 1 (Chat):

```json
{
  "type": "chat_response",
  "data": {
    "message": "I'll create a dialog node with Elena offering help, followed by a hub node for the player's choice, and connect them together."
  }
}
```

### Agent Response 2 (Function Batch):

```json
{
  "type": "function_call_batch",
  "data": {
    "request_id": "req_001",
    "functions": [
      {
        "function": "create_node",
        "arguments": {
          "type": "dialog",
          "position": "auto",
          "data": {
            "character": 4,
            "lines": [
              "I've been watching you, stranger.",
              "You seem to be on a noble quest.",
              "Perhaps I can help you on your journey?"
            ]
          },
          "connect_from": {
            "node_id": "last_selected",
            "slot": 0
          }
        }
      },
      {
        "function": "create_node",
        "arguments": {
          "type": "hub",
          "position": "below_previous",
          "data": {
            "options": [
              "Accept Elena's help",
              "Politely decline",
              "Ask what she wants in return"
            ]
          },
          "connect_from": {
            "node_id": "last_created",
            "slot": 0
          }
        }
      }
    ]
  }
}
```

### Client Response:

```json
{
  "type": "function_result",
  "data": {
    "request_id": "req_001",
    "success": true,
    "result": {
      "created_nodes": [47, 48],
      "created_connections": 2
    }
  }
}
```

---

## Implementation Notes

### Client Implementation (Arrow/GDScript)

1. **WebSocket Connection**: Use Godot's WebSocket client
2. **Function Dispatcher**: Map function names to internal Arrow functions
3. **Reference Resolution**: Resolve keywords like `"last_created"` to actual IDs
4. **Position Calculation**: Convert position strings to Vector2
5. **Error Handling**: Catch and report Arrow errors back to server

### Server Implementation (Python/Node.js)

1. **State Sync**: Parse and maintain `.arrow` file structure in memory
2. **PDF Processing**: Extract and index PDF content for RAG
3. **LLM Integration**: Use OpenAI/Anthropic with function calling
4. **Context Building**: Include relevant PDF content in prompts
5. **Function Planning**: Convert user intent to function call sequences

---

## Error Codes

| Code                   | Description                                |
| ---------------------- | ------------------------------------------ |
| `INVALID_NODE_TYPE`    | Unknown node type                          |
| `INVALID_NODE_ID`      | Node ID doesn't exist                      |
| `INVALID_SCENE_ID`     | Scene ID doesn't exist                     |
| `INVALID_VARIABLE_ID`  | Variable ID doesn't exist                  |
| `INVALID_CHARACTER_ID` | Character ID doesn't exist                 |
| `INVALID_CONNECTION`   | Connection slots incompatible              |
| `RESOURCE_IN_USE`      | Cannot delete resource with references     |
| `INVALID_POSITION`     | Position specification invalid             |
| `TYPE_MISMATCH`        | Data type doesn't match variable type      |
| `CIRCULAR_REFERENCE`   | Operation would create circular dependency |
| `PARSE_ERROR`          | Could not parse .arrow file                |
| `PERMISSION_DENIED`    | Operation not allowed in current context   |

---

## LLM System Prompt Template

```
You are an AI assistant for Arrow, a narrative design tool for games and interactive stories.

## Your Capabilities
You help users create and modify narrative structures using a node-based system. You can:
- Create narrative content nodes (dialog, content, monologs)
- Set up branching logic (conditions, hubs, randomizers)
- Manage variables and character data
- Structure scenes and narrative flow
- Reference uploaded PDF documents containing story context

## Available Node Types
1. **dialog**: Multi-line character speech
2. **content**: Descriptive text/narration
3. **monolog**: Single line character speech
4. **condition**: Branch based on variable comparison
5. **hub**: Multiple choice branching
6. **interaction**: Interactive action choices
7. **variable_update**: Modify variable values
8. **jump**: Jump to other nodes/scenes
9. **marker**: Named jump targets
10. **randomizer**: Random path selection
11. **sequencer**: Sequential path cycling
12. **generator**: Generate random values
13. **tag_edit/tag_match/tag_pass**: Character tag operations
14. **user_input**: Get player input
15. **macro_use**: Call reusable scenes
16. **entry**: Scene entry point
17. **frame**: Visual grouping

## Best Practices
- Create cohesive narrative flows by connecting nodes logically
- Use meaningful names for variables and characters
- Add notes to complex structures for clarity
- Group related nodes spatially using position: "below_previous" or "right_of_previous"
- Use macros for repeated narrative patterns
- Reference PDF context when creating narrative content

## Response Format
- First, explain what you'll do in a chat_response
- Then, execute with function_call or function_call_batch
- For complex operations, break into multiple batches

## Current Context
Scene: {current_scene_name} (ID: {current_scene_id})
Selected Nodes: {selected_node_ids}
Available Variables: {variables_list}
Available Characters: {characters_list}
PDF Documents: {pdf_documents_list}
```

---

## Complete Message Flow Example

```
[Client → Server] file_sync
  ↓
[Client → Server] user_message: "Add combat system"
  ↓
[Server → Client] status: "processing"
  ↓
[Server → Client] chat_response: "I'll create a combat flow..."
  ↓
[Server → Client] function_call_batch: [create variable, create nodes...]
  ↓
[Client → Server] function_result: success
  ↓
[Server → Client] chat_response: "Combat system created!"
  ↓
[Server → Client] status: "ready"
```

---

## Summary

This protocol provides:

✅ **Simplified API**: Complex operations abstracted to simple JSON
✅ **Smart Defaults**: Auto-positioning, auto-naming, auto-connecting
✅ **Flexible References**: Use IDs or keywords to reference resources
✅ **Clear Semantics**: Each function has one clear purpose
✅ **Error Handling**: Comprehensive error reporting
✅ **Bidirectional Communication**: Full duplex WebSocket
✅ **Batch Operations**: Execute multiple related operations atomically
✅ **Context Awareness**: Agent maintains project state and PDF context

This design makes it significantly easier for LLM agents to work with Arrow while maintaining the full power of the underlying system.
