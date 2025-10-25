We are building a narrative-design assistant built on top of the arrow project here. We want to include AI agent functionality so that the user can speak to a chat and modify the node networks of grid for the given arrow project.

We are using the parameters below.

Configuration:
Client Side: 
Server host:port

Server-side:
API Key for LLM in-question. Let's start with Claude 4.5 (with option to switch APIs later)

Adaptor;

1. Listens for server-side events using Godot websockets, polling in _process function with delta time. Create adaptor as object to be added to main.tscn
2. Dispatches events to local function calls when sent by server.
- Dispatch node change messgaes
- Dispatch chat responses received within same function too
3. Client sends save call once it's done with all server-side-events for paritcular user message in chat to save the .arrow project.

Python Server:
1. FastAPI
2. Langchain
3. To-be-designated... 

- Stream text back to chat on client.
- Use something like OpenAI chat completion (non-streaming) to generate each function to be called and call them one after the other.

Client SIde:
- Update offsets by using an autospacing algorithm for nodes created. Make sure nodes are linked however. AI agent will create nodes that have placeholder offsets from 0,0 on the grid.
- Stop central_event_dispatcher checkpoints when a chat message is sent from client to server. Enable checkpoints once all events sent by server are complete to allow undo rollback to project structure to before last AI changes.
- Disable chat until all events sent by server are reached back to client.
- Wait for an END message. Use state machine of ServerEvents.START and ServerEvents.END to determine when to start and disable chat.
- Client must also send information back to the server if applying an operation failed (exception occurred). Agent uses exception information to try again.
- Sync file with server before everytime the next message is sent on the chat.
- Arrow project file is sent to server using the websocket when projected is opened. Every time project is saved, the same function is called to sync project with server. Source-of-truth remains on client-side.
- Send local chat history on client side to server on each message.
- Add button to clear local chat history.
- Add button after message is sent to server to stop processing on server side (stop signal). This stop signal forces local rollback to before current chat began.

Here is central mind below.

@central_mind.gd 

Websocket example:
```
extends Node

# The URL we will connect to.
var websocket_url = "ws://localhost:12345" # Replace with actual server address and port
var socket := WebSocketPeer.new()

func _ready():
    if socket.connect_to_url(websocket_url) != OK:
        print("Could not connect.")
        set_process(false)

func _process(_delta):
    socket.poll()

    if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
        while socket.get_available_packet_count():
            var packet = socket.get_packet()
            if socket.was_string_packet():
                var packet_text = packet.get_string_from_ascii()
                print("Received text: ", packet_text)
                # Dispatch the event to a local function
                handle_server_event(packet_text)
            else:
                print("Received binary data: ", packet.size(), " bytes")

func _exit_tree():
    socket.close()

func handle_server_event(message: String):
    # Example: Dispatch based on message content
    match message:
        "ping":
            print("Received ping event")
            # Perform local action
        "game_start":
            print("Game start event received")
            # Start game logic
        _:
            print("Unknown event: ", message)
```

Future:
- Allow a directory as corpus for narrative design document, character design document, etc per arrow project. Switch directories everytime we switch between projects, so the right context is used by the server AI agent. Another endpoint on server receives a POST request from client containing all the information from each document in corpus.

Finalized API for AI agent to call:

# Create and insert nodes
func create_insert_node(type: String, offset: Vector2, scene_id: int = -1, draw: bool = true, name_prefix: String = "", preset: Dictionary = {}) -> int
func quick_insert_node(node_type: String, offset: Vector2, connection = null) -> void
func update_node(node_id: int, name: String = "", data: Dictionary = {}, notes: String = "", is_auto_update: bool = false) -> void:
func remove_node(node_id: int, forced: bool = false) -> bool:

# Update node properties
func update_node_map(node_id: int, modification: Dictionary, scene_id: int = -1) -> void

# Scene operations
func create_new_scene(is_macro: bool = false) -> void
func update_scene(scene_id: int, name: String = "", entry: int = -1, macro: bool = null, notes: String = "") -> void:
func remove_scene(scene_id: int, forced: bool = false) -> bool:

# Variables
func create_new_variable(type: String) -> void
func update_variable(variable_id: int, name: String = "", type: String = "", initial_value = null, notes: String = "") -> void:
func remove_variable(variable_id: int, forced: bool = false) -> bool:

# Characters
func create_new_character() -> void
func update_character(character_id: int, name: String = "", color: String = "", tags: Dictionary = {}, notes: String = "") -> void:
func remove_character(character_id: int, forced: bool = false) -> bool:

# Utility functions
func node_connection_replacement(conversation_table: Dictionary, remake_lost_connections: bool = true) -> Array

# Entry points
func update_scene_entry(node_id: int) -> int
func update_project_entry(node_id: int) -> int

# JSON Specifications
1. File Sync Message

```json
{
  "type": "file_sync",
  "data": {
    "project_id": 1,
    "arrow_content": "<complete .arrow file content as string>",
    "timestamp": 1698765432
  }
}
```


2. Design doc sync [Later]

```json
{
  "type": "design_doc_sync",
  "data": {
    "project_id": 1,
    "file_content": "base 64 pdf",
    "file_name": "",
    "timestamp": 1698765432
  }
}
```

3. User Message

```json
{
  "type": "user_message",
  "data": {
    "message": "Add a dialog node where the protagonist asks about the ancient artifact",
    "history": [
      {"message": "x1", "output": "y1"},
      {"message": "x2", "output": "y2"},
      ],
    "selected_node_ids": [12, 15],
    "current_scene_id": 5,
    "current_project_id": 1,
  }
}
```

4. Function Result

```json
{
  "type": "function_result",
  "data": {
    "request_id": "req_12345",
    "success": true,
    "result": "Node created successfully",
    "error": ""
  }
}
```

Or on error:

```json
{
  "type": "function_result",
  "data": {
    "request_id": "req_12345",
    "success": false,
    "result": "",
    "error": "Node type 'invalid_type' does not exist"
  }
}
```

5. Stop Signal - Tell server to stop processing current request. 

```json
{
  "type": "stop"
}
```