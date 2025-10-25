# Arrow-AI
# Game Narrative Design Tool w/ AI
# Kushagra Sethi

# AI WebSocket Adapter
# Handles WebSocket communication with the AI server

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
var server_host: String = "localhost"
var server_port: int = 8000

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
		if websocket.get_available_packet_count() > 0:
			var packet = websocket.get_packet()
			if packet.size() > 0:
				_handle_incoming_data(packet)
		
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
		
		# Check for connection errors
		var close_code = websocket.get_close_code()
		if close_code != 0:
			var error_msg = "Connection closed with code: " + str(close_code)
			connection_error.emit(error_msg)
			print("[AIWebSocket] ", error_msg)

func connect_to_server(host: String = "", port: int = -1) -> bool:
	"""Connect to the WebSocket server"""
	
	# Use provided host/port or defaults
	server_host = host if host != "" else server_host
	server_port = port if port != -1 else server_port
	
	# Validate inputs
	if server_host == "" or server_port <= 0:
		printerr("[AIWebSocket] Invalid host or port: ", server_host, ":", server_port)
		return false
	
	# Create connection URL
	var url = "ws://%s:%d" % [server_host, server_port]
	print("[AIWebSocket] Connecting to ", url)
	
	# Initialize connection
	var error = websocket.connect_to_url(url)
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
	
	message_queue.append(message)

func send_file_sync(project_id: int, arrow_content: String, timestamp: int = -1) -> void:
	"""Send file synchronization message"""
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
					   current_scene_id: int = -1, current_project_id: int = -1) -> void:
	"""Send a user message to the server"""
	send_message({
		"type": "user_message",
		"data": {
			"message": message,
			"history": history,
			"selected_node_ids": selected_node_ids,
			"current_scene_id": current_scene_id,
			"current_project_id": current_project_id
		}
	})

func send_function_result(request_id: String, success: bool, result = null, 
						 error: String = "", affected_nodes: Dictionary = {}) -> void:
	"""Send function execution result to the server"""
	var message: Dictionary = {
		"type": "function_result",
		"data": {
			"request_id": request_id,
			"success": success,
		}
	}
	
	if success and result != null:
		message.data["result"] = result
	elif not success and error != "":
		message.data["error"] = error
		if affected_nodes.size() > 0:
			message.data["affected_nodes"] = affected_nodes
	
	send_message(message)

func send_stop_signal() -> void:
	"""Send stop signal to the server"""
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
		var packet = json_string.to_utf8_buffer()
		
		var error = websocket.send(packet)
		if error == OK:
			bytes_sent += packet.size()
			messages_sent += 1
		else:
			printerr("[AIWebSocket] Failed to send message: ", error)
			connection_error.emit("Failed to send message: Error " + str(error))

func _handle_incoming_data(packet: PackedByteArray) -> void:
	"""Parse and handle incoming data from the server"""
	bytes_received += packet.size()
	messages_received += 1
	
	var json_string = packet.get_string_from_utf8()
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		printerr("[AIWebSocket] Failed to parse incoming message: ", json.get_error_message())
		return
	
	var data = json.data
	
	if not data is Dictionary:
		printerr("[AIWebSocket] Invalid message format: expected Dictionary")
		return
	
	# Extract message type
	if not data.has("type"):
		printerr("[AIWebSocket] Missing 'type' field in message")
		return
	
	var message_type = data.type
	
	# Extract data
	var message_data = data.get("data", {})
	
	# Handle different message types
	handle_server_message(message_type, message_data)

func handle_server_message(message_type: String, data: Dictionary) -> void:
	"""Route server messages to appropriate handlers"""
	match message_type:
		"text_chunk":
			# Streaming AI response text
			var text = data.get("text", "")
			if text != "":
				text_chunk_received.emit(text)
		
		"function_call":
			# Command to execute
			var request_id = data.get("request_id", "")
			var function_name = data.get("function_name", "")
			var args = data.get("args", {})
			
			if request_id != "" and function_name != "":
				function_call_received.emit(request_id, function_name, args)
		
		"operation_start":
			# Set state to PROCESSING
			var request_id = data.get("request_id", "")
			if request_id != "":
				operation_start_received.emit(request_id)
		
		"operation_end":
			# Set state to IDLE, save project
			operation_end_received.emit()
		
		_:
			# Unknown message type
			printerr("[AIWebSocket] Unknown message type: ", message_type)
	
	# Emit generic message received signal
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
