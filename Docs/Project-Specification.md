<!-- 8333248c-a1fd-4cc5-b6e5-c4afca928407 c2574376-249e-4609-a573-e505eb89777a -->
# Arrow AI Client-Side Implementation Plan

## Overview

Implement a collapsible AI chat panel with WebSocket communication to a Python server. The AI agent will receive commands from the server to modify the Arrow project's node network, with automatic layout spacing, error handling, and project synchronization.

## Core Components to Create

### 1. WebSocket Adapter (`Arrow/scripts/core/ai_websocket_adapter.gd`)

- Create a WebSocketPeer-based adapter class that connects to the server
- Poll for messages in `_process()` with delta time accumulation
- Parse incoming JSON messages and dispatch to appropriate handlers
- Send outgoing messages (user messages, function results, file sync, stop signals)
- Handle connection state management (connecting, open, closed, error)

**Key Functions:**

```gdscript
func connect_to_server(host: String, port: int) -> bool
func send_message(message: Dictionary) -> void
func _process(delta: float) -> void
func handle_server_message(message_type: String, data: Dictionary) -> void
```

### 2. AI State Machine (`Arrow/scripts/core/ai_state_manager.gd`)

- Manage AI operation states: `IDLE`, `PROCESSING`, `EXECUTING`
- Save checkpoint when transitioning from IDLE to PROCESSING
- Track current operation request IDs
- Handle rollback to saved checkpoint on stop signal from client
- History checkpoints continue normally during all AI states for each operation

**State Enum:**

```gdscript
enum AIState {
    IDLE,        # No AI operation
    PROCESSING,  # Server is thinking
    EXECUTING    # Commands being applied
}
```

**Key Variables:**

```gdscript
var ai_operation_start_checkpoint_index: int = -1  # History index when AI started
```

### 3. AI Chat Panel UI (`Arrow/scripts/editor/panels/ai_chat.gd` + scene)

- Create collapsible side panel similar to Inspector/Console
- Chat message display (user messages + AI responses)
- Text input field with send button
- Clear chat history button
- Stop processing button (visible only during PROCESSING/EXECUTING)
- Connection status indicator
- Disable input during PROCESSING/EXECUTING states

**UI Structure:**

- Panel container with titlebar (drag handle, collapse button)
- Scrollable chat display area
- Message input field at bottom
- Action buttons toolbar

### 4. AI Command Dispatcher (`Arrow/scripts/core/ai_command_dispatcher.gd`)

- Receive function call commands from server
- Map command names to Mind functions
- Execute commands and capture results/errors
- Send function_result messages back to server
- Include affected node states in error responses

**Supported Commands (from specification):**

- `create_insert_node`
- `quick_insert_node`
- `update_node` (wrapper for `update_resource`)
- `remove_node` (wrapper for `remove_resource`)
- `update_node_map`
- `create_new_scene`
- `update_scene` (wrapper for scene resource update)
- `remove_scene`
- `create_new_variable`
- `update_variable`
- `remove_variable`
- `create_new_character`
- `update_character`
- `remove_character`
- `update_scene_entry`
- `update_project_entry`

### 5. Auto-Layout Integration

- Hook into AI node creation to apply auto-spacing
- Use existing `Arrow/scripts/core/layout_calculation.gd`
- Call `calculate_optimal_position()` for nodes created at (0,0)
- Apply spacing after each AI-created node

### 6. Project Synchronization

- Sync project file to server on project open
- Sync on every save operation
- Send complete .arrow file content as JSON string
- Include project_id, timestamp in sync messages

## UI Integration

### Add AI Chat Panel to main.tscn

- Add new PanelContainer at `Main/Editor/AIPanel` (sibling to Center, not in FloatingTools)
- Use HBoxContainer layout in Editor to allow AIPanel to push Center left when opened
- Position AIPanel on the right side with `size_flags_horizontal = FILL`
- Add collapsible functionality (show/hide toggles panel width)
- Add to PANELS_PATHS in `main_ui_management.gd` as "ai_chat"
- Create toggle button in editor toolbar

**Layout Structure:**

```
Main/Editor (VBoxContainer)
├── Top (Bar with menus)
├── HBoxContainer (new wrapper for Center + AIPanel)
│   ├── Center (GraphEdit - existing, set size_flags_horizontal = EXPAND_FILL)
│   └── AIPanel (PanelContainer - new, collapsible, right side)
└── Bottom (Query bar)
```

When AIPanel is visible, it takes up space and Center automatically adjusts. When hidden, Center expands to full width.

### Update Preferences Panel

- Add "AI Agent" section in preferences
- WebSocket server host field (default: "localhost")
- WebSocket server port field (default: 8000)
- Auto-connect on startup checkbox
- Save/load from configuration file

## Message Protocol Implementation

### Client → Server Messages

**1. File Sync:**

```json
{
  "type": "file_sync",
  "data": {
    "project_id": 1,
    "arrow_content": "<JSON string>",
    "timestamp": 1234567890
  }
}
```

**2. User Message:**

```json
{
  "type": "user_message",
  "data": {
    "message": "Add a dialog node...",
    "history": [...],
    "selected_node_ids": [12, 15],
    "current_scene_id": 5,
    "current_project_id": 1
  }
}
```

**3. Function Result:**

```json
{
  "type": "function_result",
  "data": {
    "request_id": "req_12345",
    "success": true/false,
    "result": "...",
    "error": "...",
    "affected_nodes": {...}  // Include on error
  }
}
```

**4. Stop Signal:**

```json
{
  "type": "stop"
}
```

### Server → Client Messages

The AI chat panel will parse and handle:

- `text_chunk` - Streaming AI response text
- `function_call` - Command to execute
- `operation_start` - Set state to PROCESSING
- `operation_end` - Set state to IDLE, save project

## Modified Central Mind Functions

### History Checkpoint Management

History checkpoints continue normally during all AI operations. Each operation creates its own checkpoints as usual.

Add checkpoint save when AI operation starts:

```gdscript
func on_ai_operation_start() -> void:
    # Save current history index when transitioning from IDLE to PROCESSING
    AIStateManager.save_operation_start_checkpoint(_HISTORY.INDEX)
```

### Save Hook for Sync

Modify `central_mind.gd::save_project()`:

```gdscript
func save_project(...):
    # ... existing save logic
    # Sync with AI server after successful save
    if AIWebSocketAdapter.is_connected():
        AIWebSocketAdapter.sync_project_file()
```

## Integration Points

### Main Scene Setup

1. Add AI chat panel node to `Arrow/main.tscn`
2. Add WebSocket adapter as autoload or Main child
3. Add AI state manager as singleton
4. Connect adapter signals to chat panel and dispatcher

### Mind Integration

1. Add reference to AI adapter in Mind class
2. Save checkpoint when AI operations start (transitioning from IDLE to PROCESSING)
3. Hook project save to trigger sync
4. Provide Mind reference to AI command dispatcher

### Configuration

1. Add AI settings to Settings.gd constants
2. Add AI config section to preferences panel
3. Load/save WebSocket settings with other configs

## Error Handling & Rollback

### On Operation Failure

1. Capture exception details and stack trace
2. Console log error for debugging purposes in Godot
3. Rollback one step to right before the operation was applied
4. Send function_result with error=true, including error message
5. Server will loop, think, and send new commands to rectify the issue
6. Apply succeeding operations after the rollback

### On Stop Signal

1. Set AIState to IDLE
2. Rollback to saved checkpoint when AI operations started (from IDLE to PROCESSING)
3. Clear pending operations queue
4. Display "Operation stopped" in chat

## Websocket API

### Create and insert nodes
func create_insert_node(type: String, offset: Vector2, scene_id: int = -1, draw: bool = true, name_prefix: String = "", preset: Dictionary = {}) -> int
func quick_insert_node(node_type: String, offset: Vector2, connection = null) -> void
func update_node(node_id: int, name: String = "", data: Dictionary = {}, notes: String = "", is_auto_update: bool = false) -> void:
func remove_node(node_id: int, forced: bool = false) -> bool:

### Update node properties
func update_node_map(node_id: int, modification: Dictionary, scene_id: int = -1) -> void

### Scene operations
func create_new_scene(is_macro: bool = false) -> void
func update_scene(scene_id: int, name: String = "", entry: int = -1, macro: bool = null, notes: String = "") -> void:
func remove_scene(scene_id: int, forced: bool = false) -> bool:

### Variables
func create_new_variable(type: String) -> void
func update_variable(variable_id: int, name: String = "", type: String = "", initial_value = null, notes: String = "") -> void:
func remove_variable(variable_id: int, forced: bool = false) -> bool:

### Characters
func create_new_character() -> void
func update_character(character_id: int, name: String = "", color: String = "", tags: Dictionary = {}, notes: String = "") -> void:
func remove_character(character_id: int, forced: bool = false) -> bool:

### Utility functions
func node_connection_replacement(conversation_table: Dictionary, remake_lost_connections: bool = true) -> Array

### Entry points
func update_scene_entry(node_id: int) -> int
func update_project_entry(node_id: int) -> int

## Files to Create

1. `Arrow/scripts/core/ai_websocket_adapter.gd` - WebSocket communication
2. `Arrow/scripts/core/ai_state_manager.gd` - State machine singleton
3. `Arrow/scripts/core/ai_command_dispatcher.gd` - Command execution
4. `Arrow/scripts/editor/panels/ai_chat.gd` - Chat panel logic
5. `Arrow/scripts/editor/panels/ai_chat.tscn` - Chat panel UI scene
6. `Arrow/scripts/editor/panels/preferences_ai.gd` - AI settings in preferences

## Files to Modify

1. `Arrow/scripts/core/central_mind.gd`

   - Add AI adapter reference
   - Save checkpoint when transitioning from IDLE to PROCESSING
   - Hook save for project sync

2. `Arrow/scripts/main.gd`

   - Add AI adapter initialization
   - Add AI panel toggle handler

3. `Arrow/main.tscn`

   - Add AI chat panel to FloatingTools
   - Add toolbar toggle button

4. `Arrow/scripts/core/main_ui_management.gd`

   - Register AI chat panel
   - Add panel visibility management

5. `Arrow/scripts/settings.gd`

   - Add AI agent default settings

6. `Arrow/scripts/editor/panels/preferences.gd`

   - Add AI settings section

## Implementation Order

1. Create AI state manager singleton
2. Create WebSocket adapter with basic connection
3. Create chat panel UI and scene
4. Integrate chat panel into main scene
5. Add preferences for WebSocket config
6. Implement message protocol (send/receive)
7. Create command dispatcher
8. Hook dispatcher to Mind functions
9. Implement auto-layout on AI node creation
10. Add project sync on save/open
11. Implement error handling and rollback
12. Add chat history management
13. Testing and refinement

### To-dos

- [x] Create AI state manager singleton with IDLE/PROCESSING/EXECUTING states
- [ ] Create WebSocket adapter for server communication with polling in _process()
- [ ] Create AI chat panel UI scene and script with collapsible sidebar design
- [ ] Add AI settings section to preferences panel for WebSocket host:port configuration
- [ ] Integrate chat panel into main.tscn and main_ui_management.gd
- [ ] Implement JSON message protocol for client-server communication
- [ ] Create AI command dispatcher to map server commands to Mind functions
- [ ] Modify central_mind.gd to save checkpoint when transitioning from IDLE to PROCESSING
- [ ] Hook project save/open to sync .arrow file content with server
- [ ] Integrate auto-layout calculation for AI-created nodes at (0,0)
- [ ] Implement error handling with console logging, rollback one step, and error reporting to server
- [ ] Implement stop signal handling with rollback to saved checkpoint when operations started
- [ ] Implement local chat history storage and clear functionality