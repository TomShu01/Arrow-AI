# Arrow-AI
# Game Narrative Design Tool w/ AI
# Kushagra Sethi

# AI WebSocket Adapter
# Handles WebSocket communication with the AI server
#
# This adapter manages bidirectional communication with the AI server:
#
# CLIENT → SERVER MESSAGES:
# - file_sync: Synchronize project file with server
# - user_message: Send user chat messages
# - function_result: Return results of executed function calls
# - stop: Signal to stop current AI operation
#
# SERVER → CLIENT MESSAGES:
# - text_chunk: Streaming AI response text
# - function_call: Command to execute (maps to Arrow API functions)
# - operation_start: Begin AI operation (transition to PROCESSING state)
# - operation_end: Complete AI operation (transition to IDLE state)
#
# SUPPORTED API FUNCTIONS (called via function_call messages):
# - create_insert_node, quick_insert_node, update_node, remove_node
# - update_node_map
# - create_new_scene, update_scene, remove_scene
# - create_new_variable, update_variable, remove_variable
# - create_new_character, update_character, remove_character
# - node_connection_replacement
# - update_scene_entry, update_project_entry

class_name AIWebSocketAdapter
extends Node

# Connection state
enum ConnectionState {
	DISCONNECTED,
	CONNECTING,
	CONNECTED,
	CLOSING,
	ERROR
}

var connection_state: ConnectionState = ConnectionState.DISCONNECTED
var websocket: WebSocketPeer
var server_url: String = "ws://localhost:8000/ws/chat"

# Message queue for sending messages
var message_queue: Array[Dictionary] = []

# Signals
signal connection_state_changed(new_state: ConnectionState)
signal message_received(message_type: String, data: Dictionary)
signal text_chunk_received(text: String)
signal function_call_received(request_id: String, function_name: String, args: Dictionary)
signal operation_start_received(request_id: String)
signal operation_end_received()
signal connection_error(error_message: String)

# Statistics
var bytes_sent: int = 0
var bytes_received: int = 0
var messages_sent: int = 0
var messages_received: int = 0

func _init():
	websocket = WebSocketPeer.new()
	connection_state = ConnectionState.DISCONNECTED

func _exit_tree():
	"""Clean up WebSocket connection when node is removed"""
	if is_server_connected():
		websocket.close()

func _process(_delta: float) -> void:
	# Poll the socket for updates
	websocket.poll()
	
	if websocket.get_ready_state() == WebSocketPeer.STATE_CONNECTING:
		if connection_state != ConnectionState.CONNECTING:
			connection_state = ConnectionState.CONNECTING
			connection_state_changed.emit(connection_state)
			print("[AIWebSocket] Connecting to server...")
	
	elif websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		if connection_state != ConnectionState.CONNECTED:
			connection_state = ConnectionState.CONNECTED
			connection_state_changed.emit(connection_state)
			print("[AIWebSocket] Connected to server")
		
		# Process incoming messages (limit to one per frame to avoid blocking)
		var packet_count = websocket.get_available_packet_count()
		if packet_count > 0:
			print("[AIWebSocket] Processing ", packet_count, " packet(s)")
			var packet = websocket.get_packet()
			if packet.size() > 0:
				_handle_incoming_data(packet)
			else:
				print("[AIWebSocket] WARNING: Received empty packet")
		
		# Send queued messages
		_process_message_queue()
	
	elif websocket.get_ready_state() == WebSocketPeer.STATE_CLOSING:
		if connection_state != ConnectionState.CLOSING:
			connection_state = ConnectionState.CLOSING
			connection_state_changed.emit(connection_state)
			print("[AIWebSocket] Closing connection...")
	
	elif websocket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		if connection_state != ConnectionState.DISCONNECTED:
			connection_state = ConnectionState.DISCONNECTED
			connection_state_changed.emit(connection_state)
			print("[AIWebSocket] Disconnected from server")
			
			# Check for connection errors (only when state changes)
			var close_code = websocket.get_close_code()
			if close_code != 0 and close_code != 1000:  # 1000 = normal closure
				var error_msg = "Connection closed with code: " + str(close_code)
				connection_error.emit(error_msg)
				print("[AIWebSocket] ", error_msg)

func connect_to_server(url: String = "") -> bool:
	"""Connect to the WebSocket server using a full WebSocket URL"""
	
	# Use provided URL or default
	if url != "":
		server_url = url
	
	# Validate URL
	if server_url == "":
		printerr("[AIWebSocket] Invalid WebSocket URL: empty")
		return false
	
	# Validate URL format (should start with ws:// or wss://)
	if not (server_url.begins_with("ws://") or server_url.begins_with("wss://")):
		printerr("[AIWebSocket] Invalid WebSocket URL format: ", server_url, " (must start with ws:// or wss://)")
		return false
	
	print("[AIWebSocket] Connecting to ", server_url)
	
	# Initialize connection
	var error = websocket.connect_to_url(server_url)
	if error != OK:
		connection_state = ConnectionState.ERROR
		connection_state_changed.emit(connection_state)
		connection_error.emit("Failed to connect: Error " + str(error))
		printerr("[AIWebSocket] Failed to connect: ", error)
		return false
	
	connection_state = ConnectionState.CONNECTING
	connection_state_changed.emit(connection_state)
	return true

func disconnect_from_server() -> void:
	"""Disconnect from the WebSocket server"""
	if websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		websocket.close()
		connection_state = ConnectionState.CLOSING
		connection_state_changed.emit(connection_state)
		print("[AIWebSocket] Disconnecting from server...")

func send_message(message: Dictionary) -> void:
	"""Queue a message to be sent to the server"""
	if not is_server_connected():
		printerr("[AIWebSocket] Cannot send message: not connected")
		return
	
	print("[AIWebSocket] Message added to queue (queue size: ", message_queue.size() + 1, ")")
	message_queue.append(message)

func send_file_sync(project_id: int, arrow_content: String, timestamp: int = -1) -> void:
	"""
	Send file synchronization message to server
	Syncs the complete .arrow project file content
	
	Message format:
	{
	  "type": "file_sync",
	  "data": {
	    "project_id": int,
	    "arrow_content": string (JSON string of .arrow file),
	    "timestamp": int (unix timestamp)
	  }
	}
	"""
	if timestamp == -1:
		timestamp = Time.get_unix_time_from_system()
	
	send_message({
		"type": "file_sync",
		"data": {
			"project_id": project_id,
			"arrow_content": arrow_content,
			"timestamp": timestamp
		}
	})

func send_user_message(message: String, history: Array, selected_node_ids: Array = [], 
					   current_scene_id: int = -1, current_project_id: int = -1, 
					   mind: CentralMind.Mind = null) -> void:
	"""
	Send user chat message to server with embedded project content
	Saves project before sending and embeds the complete .arrow file content
	
	Message format (fields at top level, no nesting):
	{
	  "type": "user_message",
	  "message": string,
	  "arrow_content": string (complete .arrow file as JSON string),
	  "history": array of {message: string, output: string},
	  "selected_node_ids": array of ints,
	  "current_scene_id": int,
	  "current_project_id": int
	}
	"""
	# Validate Mind reference before attempting save
	if not mind:
		printerr("[AIWebSocket] Cannot send user message: Mind reference not provided")
		connection_error.emit("Cannot send message: Mind reference not available")
		return
	
	if not mind.ProMan:
		printerr("[AIWebSocket] Cannot send user message: ProMan not available")
		connection_error.emit("Cannot send message: Project Manager not available")
		return
	
	# Save project before sending (ensures disk state matches in-memory state)
	if mind.ProMan.is_project_listed():
		print("[AIWebSocket] Saving project before sending user message...")
		mind.save_project()
		print("[AIWebSocket] Project saved successfully (ID: ", current_project_id, ")")
	else:
		printerr("[AIWebSocket] Warning: Project not listed, skipping save")
	
	# Read arrow content from disk (after save)
	var arrow_content = _read_arrow_content(mind)
	
	# Validate arrow content was successfully read
	if arrow_content.is_empty() and mind.ProMan.is_project_listed():
		printerr("[AIWebSocket] Warning: Arrow content is empty for listed project ID ", current_project_id)
		printerr("[AIWebSocket] Message will be sent with empty arrow_content - server may not have full context")
	elif not arrow_content.is_empty():
		print("[AIWebSocket] Arrow content embedded (", arrow_content.length(), " bytes)")
	
	# Convert chat history format from {role, content} to {message, output}
	var formatted_history = []
	for i in range(0, history.size(), 2):
		if i + 1 < history.size():
			var user_msg = history[i]
			var ai_msg = history[i + 1]
			if user_msg.get("role") == "user" and ai_msg.get("role") == "assistant":
				formatted_history.append({
					"message": user_msg.get("content", ""),
					"output": ai_msg.get("content", "")
				})
	
	# Send message with fields at top level (not nested under "data")
	var msg = {
		"type": "user_message",
		"message": message,
		"arrow_content": arrow_content,
		"history": formatted_history,
		"selected_node_ids": selected_node_ids,
		"current_scene_id": current_scene_id,
		"current_project_id": current_project_id
	}
	print("[AIWebSocket] Queuing user_message: ", msg.type, ", message length: ", msg.message.length())
	send_message(msg)

func send_function_result(request_id: String, success: bool, result = null, 
						 error: String = "", arrow_content: String = "", 
						 affected_nodes: Dictionary = {}) -> void:
	"""
	Send function execution result back to server with embedded project content
	
	Message format (fields at top level, no nesting):
	{
	  "type": "function_result",
	  "request_id": string,
	  "success": bool,
	  "arrow_content": string (complete .arrow file as JSON string),
	  "result": any (on success, optional),
	  "error": string (on failure, optional)
	}
	
	Args:
	  request_id: Unique identifier for the function call request
	  success: Whether the function executed successfully
	  result: Return value of the function (included if success=true)
	  error: Error message (included if success=false)
	  arrow_content: Complete .arrow file content (included if success=true)
	  affected_nodes: State of affected nodes for error recovery (not sent to server)
	"""
	var message: Dictionary = {
		"type": "function_result",
		"request_id": request_id,
		"success": success,
		"arrow_content": arrow_content
	}
	
	if success:
		if result != null:
			message["result"] = result
	else:
		if error != "":
			message["error"] = error
	
	send_message(message)

func send_stop_signal() -> void:
	"""
	Send stop signal to abort current AI operation
	Server will stop processing and client will rollback to operation start checkpoint
	
	Message format:
	{
	  "type": "stop"
	}
	"""
	send_message({
		"type": "stop"
	})

func is_server_connected() -> bool:
	"""Check if connected to the server"""
	return websocket.get_ready_state() == WebSocketPeer.STATE_OPEN

func _process_message_queue() -> void:
	"""Send queued messages to the server (one per frame to avoid blocking)"""
	if message_queue.size() > 0 and is_server_connected():
		var message = message_queue.pop_front()
		var json_string = JSON.stringify(message)
		
		print("[AIWebSocket] Sending message to server (", json_string.length(), " bytes)")
		print("[AIWebSocket] Message preview: ", json_string.substr(0, 200), "...")
		
		# Send as TEXT frame (not binary) - FastAPI expects text frames
		var error = websocket.send_text(json_string)
		if error == OK:
			bytes_sent += json_string.length()
			messages_sent += 1
			print("[AIWebSocket] Message sent successfully")
		else:
			printerr("[AIWebSocket] Failed to send message: ", error)
			connection_error.emit("Failed to send message: Error " + str(error))

func _handle_incoming_data(packet: PackedByteArray) -> void:
	"""Parse and handle incoming data from the server"""
	bytes_received += packet.size()
	messages_received += 1
	
	var json_string = packet.get_string_from_utf8()
	print("[AIWebSocket] Raw message received (", packet.size(), " bytes): ", json_string)
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		printerr("[AIWebSocket] Failed to parse incoming message: ", json.get_error_message())
		return
	
	var data = json.data
	print("[AIWebSocket] Parsed JSON data: ", data)
	
	if not data is Dictionary:
		printerr("[AIWebSocket] Invalid message format: expected Dictionary, got ", typeof(data))
		return
	
	# Extract message type
	if not data.has("type"):
		printerr("[AIWebSocket] Missing 'type' field in message")
		return
	
	var message_type = data.type
	print("[AIWebSocket] Message type: ", message_type)
	
	# All fields are at the top level - just pass the entire data object
	print("[AIWebSocket] Message fields: ", data)
	
	# Handle different message types
	handle_server_message(message_type, data)

func handle_server_message(message_type: String, data: Dictionary) -> void:
	"""
	Route server messages to appropriate handlers
	
	SERVER → CLIENT MESSAGE TYPES:
	
	1. connected: Initial handshake confirmation from server
	   { "type": "connected", "data": { "sessionId": string, "serverTime": int } }
	
	2. text_chunk: Streaming AI response text for chat display
	   { "type": "text_chunk", "data": { "text": string } }
	
	3. chat_response: Complete AI chat response
	   { "type": "chat_response", "data": { "message": string } }
	
	4. function_call: Command to execute via AI Command Dispatcher
	   { "type": "function_call", "data": { 
	       "request_id": string, 
	       "function_name": string,
	       "args": dict 
	   }}
	   
	   Supported function_name values:
	   - create_insert_node, quick_insert_node, update_node, remove_node
	   - update_node_map
	   - create_new_scene, update_scene, remove_scene
	   - create_new_variable, update_variable, remove_variable
	   - create_new_character, update_character, remove_character
	   - node_connection_replacement
	   - update_scene_entry, update_project_entry
	
	5. operation_start: Begin AI operation (transition to PROCESSING state)
	   { "type": "operation_start", "data": { "request_id": string } }
	
	6. operation_end / end: Complete AI operation (transition to IDLE, trigger save)
	   { "type": "operation_end" } or { "type": "end" }
	"""
	match message_type:
		"connected":
			# Server handshake confirmation
			var session_id = data.get("sessionId", "")
			var server_time = data.get("serverTime", 0)
			print("[AIWebSocket] Server connection confirmed (Session: ", session_id, ", Time: ", server_time, ")")
		
		"text_chunk":
			# Streaming AI response text
			var text = data.get("text", "")
			if text != "":
				print("[AIWebSocket] Emitting text_chunk: '", text, "'")
				text_chunk_received.emit(text)
		
		"chat_response":
			# Complete chat response message
			var message = data.get("message", "")
			if message != "":
				print("[AIWebSocket] Received chat_response: '", message, "'")
				text_chunk_received.emit(message)
		
		"function_call":
			# Command to execute via dispatcher
			var request_id = data.get("request_id", "")
			# Server sends "function" not "function_name"
			var function_name = data.get("function", data.get("function_name", ""))
			# Server sends "arguments" not "args"
			var args = data.get("arguments", data.get("args", {}))
			
			print("[AIWebSocket] Function call - request_id: ", request_id, ", function: ", function_name)
			
			if request_id != "" and function_name != "":
				function_call_received.emit(request_id, function_name, args)
			else:
				printerr("[AIWebSocket] Invalid function_call: missing request_id or function (got: ", request_id, ", ", function_name, ")")
		
		"operation_start":
			# Begin AI operation (IDLE → PROCESSING)
			var request_id = data.get("request_id", "")
			if request_id != "":
				operation_start_received.emit(request_id)
			else:
				printerr("[AIWebSocket] Invalid operation_start: missing request_id")
		
		"operation_end", "end":
			# Complete AI operation (PROCESSING → IDLE, trigger save)
			print("[AIWebSocket] Received operation end signal")
			operation_end_received.emit()
		
		_:
			# Unknown message type
			printerr("[AIWebSocket] Unknown message type: ", message_type)
	
	# Emit generic message received signal for additional handlers
	message_received.emit(message_type, data)

# Utility functions

func get_connection_state_string() -> String:
	"""Get connection state as string"""
	match connection_state:
		ConnectionState.DISCONNECTED:
			return "Disconnected"
		ConnectionState.CONNECTING:
			return "Connecting"
		ConnectionState.CONNECTED:
			return "Connected"
		ConnectionState.CLOSING:
			return "Closing"
		ConnectionState.ERROR:
			return "Error"
		_:
			return "Unknown"

func get_stats() -> Dictionary:
	"""Get connection statistics"""
	return {
		"bytes_sent": bytes_sent,
		"bytes_received": bytes_received,
		"messages_sent": messages_sent,
		"messages_received": messages_received
	}

func reset_stats() -> void:
	"""Reset connection statistics"""
	bytes_sent = 0
	bytes_received = 0
	messages_sent = 0
	messages_received = 0

# ============================================================================
# Arrow Content Reading
# ============================================================================

func _read_arrow_content(mind: CentralMind.Mind = null) -> String:
	"""
	Read the current .arrow project file content as a string
	Returns empty string if unable to read
	"""
	if not mind or not mind.ProMan:
		printerr("[AIWebSocket] Cannot read arrow content: Mind/ProMan not available")
		return ""
	
	# Get project file path
	var project_id = mind.ProMan.get_active_project_id()
	if project_id < 0:
		printerr("[AIWebSocket] No active project to read")
		return ""
	
	var project_path = mind.ProMan.get_project_file_path(project_id)
	if not project_path or project_path == "":
		printerr("[AIWebSocket] Invalid project path")
		return ""
	
	# Read file content
	if not FileAccess.file_exists(project_path):
		printerr("[AIWebSocket] Project file does not exist: ", project_path)
		return ""
	
	var file = FileAccess.open(project_path, FileAccess.READ)
	if not file:
		printerr("[AIWebSocket] Cannot open project file: ", project_path)
		return ""
	
	var content = file.get_as_text()
	file.close()
	
	print("[AIWebSocket] Read arrow content (", content.length(), " bytes)")
	return content

# =============================================================================
# API REFERENCE SUMMARY
# =============================================================================
#
# This WebSocket adapter provides the communication layer for the Arrow AI system.
# The AI server can remotely call functions to manipulate the Arrow project through
# function_call messages. The dispatcher maps these calls to actual Mind functions.
#
# COMPLETE API FUNCTION LIST (callable via function_call messages):
#
# NODE OPERATIONS:
#   create_insert_node(type: String, offset: Vector2, scene_id: int = -1, 
#                      draw: bool = true, name_prefix: String = "", 
#                      preset: Dictionary = {}) -> int
#   quick_insert_node(node_type: String, offset: Vector2, connection = null) -> void
#   update_node(node_id: int, name: String = "", data: Dictionary = {}, 
#               notes: String = "", is_auto_update: bool = false) -> void
#   remove_node(node_id: int, forced: bool = false) -> bool
#   update_node_map(node_id: int, modification: Dictionary, scene_id: int = -1) -> void
#
# SCENE OPERATIONS:
#   create_new_scene(is_macro: bool = false) -> void
#   update_scene(scene_id: int, name: String = "", entry: int = -1, 
#                macro: bool = null, notes: String = "") -> void
#   remove_scene(scene_id: int, forced: bool = false) -> bool
#
# VARIABLE OPERATIONS:
#   create_new_variable(type: String) -> void
#   update_variable(variable_id: int, name: String = "", type: String = "", 
#                   initial_value = null, notes: String = "") -> void
#   remove_variable(variable_id: int, forced: bool = false) -> bool
#
# CHARACTER OPERATIONS:
#   create_new_character() -> void
#   update_character(character_id: int, name: String = "", color: String = "", 
#                    tags: Dictionary = {}, notes: String = "") -> void
#   remove_character(character_id: int, forced: bool = false) -> bool
#
# UTILITY OPERATIONS:
#   node_connection_replacement(conversation_table: Dictionary, 
#                               remake_lost_connections: bool = true) -> Array
#
# ENTRY POINT OPERATIONS:
#   update_scene_entry(node_id: int) -> int
#   update_project_entry(node_id: int) -> int
#
# =============================================================================
