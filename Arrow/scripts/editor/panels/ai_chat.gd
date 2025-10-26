# Arrow-AI
# Game Narrative Design Tool w/ AI
# Kushagra Sethi

# AI Chat Panel
# Collapsible side panel for AI agent chat interface
# Displays chat messages, handles user input, and manages connection status

extends Control

@onready var TheTree = get_tree()
@onready var Main = TheTree.get_root().get_child(0)

# UI Components
@onready var ChatScroll = $/root/Main/Editor/Centre_Wrapper/AIChat/Sections/Chat/Scroll
@onready var ChatContainer = $/root/Main/Editor/Centre_Wrapper/AIChat/Sections/Chat/Scroll/Messages
@onready var InputField = $/root/Main/Editor/Centre_Wrapper/AIChat/Sections/Input/Field
@onready var SendButton = $/root/Main/Editor/Centre_Wrapper/AIChat/Sections/Input/Send
@onready var ConnectionStatus = $/root/Main/Editor/Centre_Wrapper/AIChat/Sections/Toolbar/Status
@onready var ConnectButton = $/root/Main/Editor/Centre_Wrapper/AIChat/Sections/Toolbar/Connect
@onready var StopButton = $/root/Main/Editor/Centre_Wrapper/AIChat/Sections/Toolbar/Stop
@onready var ClearButton = $/root/Main/Editor/Centre_Wrapper/AIChat/Sections/Toolbar/Clear
@onready var CloseButton = $/root/Main/Editor/Centre_Wrapper/AIChat/Sections/Toolbar/Close
@onready var ResizeHandle = $/root/Main/Editor/Centre_Wrapper/ResizeHandle
@onready var DisabledOverlay = $/root/Main/Editor/Centre_Wrapper/AIChat/DisabledOverlay

# Chat settings
var _AUTOSCROLL: bool = true
var _chat_history: Array = []  # Stores chat messages for context
var _current_ai_message: String = ""  # Accumulator for streaming AI responses
var _streaming_message_label: Label = null  # Reference to the currently streaming message label

# Resize functionality
var _is_resizing: bool = false
var _resize_start_mouse_pos: Vector2
var _resize_start_panel_width: float
const MIN_PANEL_WIDTH: float = 250.0
const MAX_PANEL_WIDTH: float = 800.0

# Color constants
const USER_MESSAGE_COLOR = Color("0fcbf4")  # Cyan - from Settings.PEACE_COLOR
const AI_MESSAGE_COLOR = Color.GREEN_YELLOW  # From Settings.INFO_COLOR
const ERROR_MESSAGE_COLOR = Color("ff0bb1")  # Red - from Settings.WARNING_COLOR
const SYSTEM_MESSAGE_COLOR = Color.YELLOW  # From Settings.CAUTION_COLOR
const ANONYMOUS_MESSAGE_COLOR = Color.GRAY

# Message display properties
const CHAT_MESSAGE_PROPERTIES = {
	"size_flags_vertical": Control.SizeFlags.SIZE_EXPAND_FILL,
	"horizontal_alignment": HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT,
	"autowrap_mode": TextServer.AutowrapMode.AUTOWRAP_WORD_SMART,
}

func _ready() -> void:
	_register_connections()
	_initialize_panel()
	pass

func _register_connections() -> void:
	# Button connections
	SendButton.pressed.connect(self._on_send_button_pressed, CONNECT_DEFERRED)
	ClearButton.pressed.connect(self._on_clear_button_pressed, CONNECT_DEFERRED)
	CloseButton.pressed.connect(self._on_close_button_pressed, CONNECT_DEFERRED)
	ConnectButton.pressed.connect(self._on_connect_button_pressed, CONNECT_DEFERRED)
	StopButton.pressed.connect(self._on_stop_button_pressed, CONNECT_DEFERRED)
	
	# Input field connections
	InputField.text_submitted.connect(self._on_input_text_submitted, CONNECT_DEFERRED)
	
	# Resize handle connections
	ResizeHandle.gui_input.connect(self._on_resize_handle_input)
	
	# Note: AI WebSocket Adapter and State Manager signals are connected later
	# via connect_adapter_signals() after the adapter is initialized in Main
	pass

func connect_adapter_signals() -> void:
	"""Connect to AI WebSocket Adapter signals - called by Main after adapter initialization"""
	# AI WebSocket Adapter signals
	if Main.has_node("AIWebSocketAdapter"):
		var adapter = Main.get_node("AIWebSocketAdapter")
		
		# Test if signals exist
		print("[AIChat] Adapter has text_chunk_received signal: ", adapter.has_signal("text_chunk_received"))
		print("[AIChat] Adapter has operation_end_received signal: ", adapter.has_signal("operation_end_received"))
		
		adapter.connection_state_changed.connect(self._on_connection_state_changed, CONNECT_DEFERRED)
		adapter.text_chunk_received.connect(self._on_text_chunk_received, CONNECT_DEFERRED)
		adapter.connection_error.connect(self._on_connection_error, CONNECT_DEFERRED)
		adapter.operation_end_received.connect(self._on_operation_end, CONNECT_DEFERRED)
		adapter.message_received.connect(self._on_message_received, CONNECT_DEFERRED)
		print("[AIChat] Connected to AIWebSocketAdapter signals")
		
		# Update UI to reflect current state
		_update_ui_from_state()
	else:
		printerr("[AIChat] ERROR: AIWebSocketAdapter not found!")
	
	# AI State Manager signals
	if Main.has_node("AIStateManager"):
		var state_mgr = Main.get_node("AIStateManager")
		state_mgr.state_changed.connect(self._on_ai_state_changed, CONNECT_DEFERRED)
		print("[AIChat] Connected to AIStateManager signals")
	
	pass

func _initialize_panel() -> void:
	# Set initial button states
	_update_ui_from_state()
	
	# Display welcome message only if valid project is open
	if _is_valid_project_open():
		clear_chat()
		append_system_message("Connect to assistant to begin.")
	# else:
	# 	append_system_message("No project open. Open or create a named project to use AI features.")
	pass

# ============================================================================
# UI Update Methods
# ============================================================================

func _update_ui_from_state() -> void:
	"""Update UI elements based on connection and AI state"""
	var is_valid_project = _is_valid_project_open()
	var is_server_connected = _is_websocket_connected()
	var ai_state = _get_ai_state()
	var is_busy = (ai_state != null and ai_state != 0)  # Not IDLE
	
	# Show/hide disabled overlay based on project validation
	if DisabledOverlay:
		if not is_valid_project:
			clear_chat()
			DisabledOverlay.set_visible(true)
		else:
			DisabledOverlay.set_visible(false)
	
	# Disable all interactive controls when no valid project
	var controls_enabled = is_valid_project
	
	# Update connection status indicator
	if is_server_connected:
		ConnectionStatus.set_text("● Connected")
		ConnectionStatus.add_theme_color_override("font_color", Color.GREEN)
	else:
		ConnectionStatus.set_text("○ Disconnected")
		ConnectionStatus.add_theme_color_override("font_color", Color.GRAY)
	
	# Update button states (disabled if no valid project)
	ConnectButton.set_disabled(is_server_connected or not controls_enabled)
	ConnectButton.set_text("Disconnect" if is_server_connected else "Connect")
	
	StopButton.set_visible(is_busy and controls_enabled)
	StopButton.set_disabled(not is_busy or not controls_enabled)
	
	SendButton.set_disabled(not is_server_connected or is_busy or not controls_enabled)
	InputField.set_editable(is_server_connected and not is_busy and controls_enabled)
	ClearButton.set_disabled(not controls_enabled)
	
	pass

func _update_scroll_to_max(forced: bool = false) -> void:
	"""Scroll chat to bottom"""
	if _AUTOSCROLL or forced:
		await TheTree.process_frame
		var v_max = ChatScroll.get_v_scroll_bar().get_max()
		ChatScroll.set_v_scroll(v_max)
		ChatScroll.queue_redraw()
	pass

# ============================================================================
# Chat Message Display
# ============================================================================

func append_user_message(message: String) -> void:
	"""Display user message in chat"""
	# Don't defer - add immediately to maintain message order
	_add_message_to_chat_immediate("User", message, USER_MESSAGE_COLOR)
	_chat_history.append({"role": "user", "content": message})
	pass

func append_ai_message(message: String) -> void:
	"""Display complete AI message in chat"""
	_add_message_to_chat("Assistant", message, AI_MESSAGE_COLOR)
	_chat_history.append({"role": "assistant", "content": message})
	pass

func append_ai_message_block(message: String) -> void:
	"""Display AI message as a new block (not streaming) - simple styling"""
	print("[AIChat] Adding AI message block: ", message)
	
	# Create message container
	var message_box = VBoxContainer.new()
	message_box.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	
	# Create message label - simple, normal size
	var message_label = Label.new()
	message_label.set_text(message)
	message_label.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	message_label.set_autowrap_mode(TextServer.AUTOWRAP_WORD_SMART)
	message_label.add_theme_color_override("font_color", Color(0.8, 0.9, 0.8))  # Light green
	
	message_box.add_child(message_label)
	
	# Add spacer
	var spacer = Control.new()
	spacer.set_custom_minimum_size(Vector2(0, 20))
	message_box.add_child(spacer)
	
	# Add to chat immediately
	ChatContainer.add_child(message_box)
	_update_scroll_to_max()
	
	_chat_history.append({"role": "assistant", "content": message})
	pass

func append_function_call_block(function_name: String, arguments: Dictionary, request_id: String) -> void:
	"""Display function call with custom UI block"""
	print("[AIChat] Adding function call block: ", function_name)
	
	# Create message container
	var message_box = VBoxContainer.new()
	message_box.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	
	# Create header with function icon/indicator
	var header = HBoxContainer.new()
	
	var icon_label = Label.new()
	icon_label.set_text("⚙️")
	icon_label.add_theme_font_size_override("font_size", 16)
	header.add_child(icon_label)
	
	var function_label = Label.new()
	function_label.set_text("Calling: " + function_name)
	function_label.add_theme_color_override("font_color", Color("FFA500"))  # Orange
	function_label.add_theme_font_size_override("font_size", 14)
	header.add_child(function_label)
	
	message_box.add_child(header)
	
	# Create arguments display (formatted JSON)
	if arguments.size() > 0:
		var args_label = Label.new()
		var args_text = "Arguments: " + JSON.stringify(arguments, "  ")
		args_label.set_text(args_text)
		args_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		args_label.add_theme_font_size_override("font_size", 12)
		for property in CHAT_MESSAGE_PROPERTIES:
			args_label.set(property, CHAT_MESSAGE_PROPERTIES[property])
		message_box.add_child(args_label)
	
	# Add spacer
	var spacer = Control.new()
	spacer.set_custom_minimum_size(Vector2(0, 20))
	message_box.add_child(spacer)
	
	# Add to chat immediately
	ChatContainer.add_child(message_box)
	_update_scroll_to_max()
	pass

func append_anonymous_message(message: String) -> void:
	"""Display anonymous message in chat"""
	_add_message_to_chat("", message, Color.WHITE, ANONYMOUS_MESSAGE_COLOR)
	pass

func append_system_message(message: String) -> void:
	"""Display system message in chat"""
	_add_message_to_chat("System", message, SYSTEM_MESSAGE_COLOR)
	pass

func append_error_message(message: String) -> void:
	"""Display error message in chat"""
	_add_message_to_chat("Error", message, ERROR_MESSAGE_COLOR)
	pass

func _add_message_to_chat(sender: String, message: String, sender_color: Color, message_color: Color = Color.WHITE) -> void:
	"""Internal method to add formatted message to chat display (deferred)"""
	# Create message container
	var message_box = VBoxContainer.new()
	message_box.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	
	# Create sender label
	var sender_label
	if sender != "":
		sender_label = Label.new()
		sender_label.set_text(sender + ":")
		sender_label.add_theme_color_override("font_color", sender_color)
		sender_label.add_theme_font_size_override("font_size", 14)
	
	# Create message label
	var message_label = Label.new()
	message_label.set_text(message)
	for property in CHAT_MESSAGE_PROPERTIES:
		message_label.set(property, CHAT_MESSAGE_PROPERTIES[property])
	message_label.add_theme_color_override("font_color", message_color)
	
	# Add to container
	if (sender != ""):
		message_box.add_child(sender_label)
	
	message_box.add_child(message_label)
	
	# Add spacer between messages
	var spacer = Control.new()
	spacer.set_custom_minimum_size(Vector2(0, 20))  # Increased spacing
	message_box.add_child(spacer)
	
	# Add to chat
	ChatContainer.call_deferred("add_child", message_box)
	self.call_deferred("_update_scroll_to_max")
	pass

func _add_message_to_chat_immediate(sender: String, message: String, sender_color: Color, message_color: Color = Color.WHITE) -> void:
	"""Internal method to add formatted message to chat display (immediate, for correct ordering)"""
	# Create message container
	var message_box = VBoxContainer.new()
	message_box.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	
	# Create sender label
	var sender_label
	if sender != "":
		sender_label = Label.new()
		sender_label.set_text(sender + ":")
		sender_label.add_theme_color_override("font_color", sender_color)
		sender_label.add_theme_font_size_override("font_size", 14)
	
	# Create message label
	var message_label = Label.new()
	message_label.set_text(message)
	for property in CHAT_MESSAGE_PROPERTIES:
		message_label.set(property, CHAT_MESSAGE_PROPERTIES[property])
	message_label.add_theme_color_override("font_color", message_color)
	
	# Add to container
	if sender != "":
		message_box.add_child(sender_label)
	message_box.add_child(message_label)
	
	# Add spacer between messages
	var spacer = Control.new()
	spacer.set_custom_minimum_size(Vector2(0, 20))  # Increased spacing
	message_box.add_child(spacer)
	
	# Add to chat immediately (not deferred)
	ChatContainer.add_child(message_box)
	_update_scroll_to_max()
	pass

func start_streaming_ai_message() -> void:
	"""Begin accumulating a new streaming AI message and create live display"""
	# Clear any existing streaming message first
	if _streaming_message_label != null and is_instance_valid(_streaming_message_label):
		finish_streaming_ai_message()
	
	_current_ai_message = ""
	print("[AIChat] Creating new AI message block")
	
	# Create a new message box for streaming AI response
	var message_box = VBoxContainer.new()
	message_box.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	
	# Create sender label
	var sender_label = Label.new()
	sender_label.set_text("AI:")
	sender_label.add_theme_color_override("font_color", AI_MESSAGE_COLOR)
	sender_label.add_theme_font_size_override("font_size", 14)
	
	# Create message label for streaming content
	_streaming_message_label = Label.new()
	_streaming_message_label.set_text("...")
	for property in CHAT_MESSAGE_PROPERTIES:
		_streaming_message_label.set(property, CHAT_MESSAGE_PROPERTIES[property])
	_streaming_message_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Add to container
	message_box.add_child(sender_label)
	message_box.add_child(_streaming_message_label)
	
	# Add spacer between messages
	var spacer = Control.new()
	spacer.set_custom_minimum_size(Vector2(0, 20))  # Increased spacing
	message_box.add_child(spacer)
	
	# Add to chat immediately (not deferred for correct ordering)
	ChatContainer.add_child(message_box)
	_update_scroll_to_max()
	pass

func append_ai_text_chunk(text: String) -> void:
	"""Add text chunk to current streaming AI message and update display in real-time"""
	# If no streaming message box exists, create one
	if _streaming_message_label == null or not is_instance_valid(_streaming_message_label):
		print("[AIChat] Starting new streaming message")
		start_streaming_ai_message()
	
	_current_ai_message += text
	print("[AIChat] Current message length: ", _current_ai_message.length(), " chars")
	
	# Update the streaming message label in real-time
	if _streaming_message_label != null and is_instance_valid(_streaming_message_label):
		_streaming_message_label.set_text(_current_ai_message)
		_update_scroll_to_max()
	pass

func finish_streaming_ai_message() -> void:
	"""Complete the streaming AI message and finalize it"""
	if _current_ai_message.length() > 0:
		# Add to chat history
		_chat_history.append({"role": "assistant", "content": _current_ai_message})
		
		# Clear streaming state
		_streaming_message_label = null
		_current_ai_message = ""
	pass

func clear_chat() -> void:
	"""Clear all chat messages"""
	for child in ChatContainer.get_children():
		child.queue_free()
	_chat_history.clear()
	_current_ai_message = ""
	pass

# ============================================================================
# Button Handlers
# ============================================================================

func _on_send_button_pressed() -> void:
	"""Handle send button click"""
	_send_message()
	pass

func _on_input_text_submitted(_text: String) -> void:
	"""Handle Enter key in input field"""
	_send_message()
	pass

func _send_message() -> void:
	"""Send user message to AI server"""
	var message = InputField.get_text().strip_edges()
	
	if message.length() == 0:
		return
	
	# Clear input field
	InputField.set_text("")
	
	# Display user message
	append_user_message(message)
	
	# Get context information
	var selected_nodes = _get_selected_node_ids()
	var current_scene_id = _get_current_scene_id()
	var current_project_id = _get_current_project_id()
	
	print("[AIChat] Sending message: ", message)
	print("[AIChat] Current scene ID: ", current_scene_id)
	print("[AIChat] Current project ID: ", current_project_id)
	
	# Send to server via WebSocket adapter (with Mind reference for project saving)
	if Main.has_node("AIWebSocketAdapter"):
		var adapter = Main.get_node("AIWebSocketAdapter")
		print("[AIChat] Calling send_user_message on adapter")
		adapter.send_user_message(message, _chat_history, selected_nodes, current_scene_id, current_project_id, Main.Mind)
		# Don't start streaming message - we'll create blocks when messages arrive
		print("[AIChat] Message sent, waiting for response")
	else:
		append_error_message("AIWebSocketAdapter not found!")
	
	pass

func _on_clear_button_pressed() -> void:
	"""Handle clear button click"""
	clear_chat()
	pass

func _on_close_button_pressed() -> void:
	"""Handle close button click"""
	# Hide the panel using the UI manager (will also hide resize handle)
	if Main.has_node("UI") or Main.has_method("get"):
		Main.UI.set_panel_visibility("ai_chat", false)
	else:
		# Fallback: directly hide the panel
		var ai_panel = Main.get_node("/root/Main/Editor/Centre_Wrapper/AIChat")
		if ai_panel:
			ai_panel.set_visible(false)
	pass

func _on_connect_button_pressed() -> void:
	"""Handle connect/disconnect button click"""
	if _is_websocket_connected():
		# Disconnect
		if Main.has_node("AIWebSocketAdapter"):
			var adapter = Main.get_node("AIWebSocketAdapter")
			adapter.disconnect_from_server()
	else:
		# Connect using settings from configuration
		if Main.has_node("AIWebSocketAdapter"):
			var adapter = Main.get_node("AIWebSocketAdapter")
			# Get WebSocket URL from configuration (default if not found)
			var ws_url = Main.Configs.CONFIRMED.get("ai_websocket_url", "ws://localhost:8000/ws/chat")
			adapter.connect_to_server(ws_url)
		else:
			append_error_message("AIWebSocketAdapter not found!")
	pass

func _on_stop_button_pressed() -> void:
	"""Handle stop button click - abort current AI operation"""
	if Main.has_node("AIWebSocketAdapter"):
		var adapter = Main.get_node("AIWebSocketAdapter")
		adapter.send_stop_signal()
		append_system_message("Stopping AI operation...")
	pass

# ============================================================================
# Signal Handlers
# ============================================================================

func _on_connection_state_changed(new_state) -> void:
	"""Handle WebSocket connection state changes"""
	_update_ui_from_state()
	
	# Display connection state messages
	if Main.has_node("AIWebSocketAdapter"):
		var adapter = Main.get_node("AIWebSocketAdapter")
		var state_string = adapter.get_connection_state_string()
		
		match new_state:
			2:  # CONNECTED
				clear_chat()
				append_ai_message("How may I help you?")
				# Sync project file on connection
				_sync_project_file()
			0:  # DISCONNECTED
				clear_chat()
				append_ai_message("Goodbye.")
			4:  # ERROR
				clear_chat()
				append_error_message("Connection Error. Please reconnect.")
	pass

func _on_text_chunk_received(text: String) -> void:
	"""Handle streaming text chunks from AI"""
	print("[AIChat] Received text chunk: ", text)
	append_ai_text_chunk(text)
	pass

func _on_connection_error(error_message: String) -> void:
	"""Handle WebSocket connection errors"""
	append_error_message("Connection error: " + error_message)
	pass

func _on_operation_end() -> void:
	"""Handle operation end signal - finalize streaming message"""
	finish_streaming_ai_message()
	print("[AIChat] AI operation ended, message finalized")
	pass

func _on_message_received(message_type: String, data: Dictionary) -> void:
	"""Handle generic messages from server - for special UI blocks"""
	print("[AIChat] Received message type: ", message_type)
	
	match message_type:
		"chat_response":
			# Create a new AI message block (not streaming)
			var message = data.get("message", "")
			if message != "":
				append_ai_message_block(message)
		
		"function_call":
			# Create a custom UI block for function calls
			var function = data.get("function", "")
			var arguments = data.get("arguments", {})
			var request_id = data.get("request_id", "")
			if function != "":
				append_function_call_block(function, arguments, request_id)
		
		"connected", "end", "operation_end", "operation_start":
			# Ignore these messages in UI (handled elsewhere)
			pass
	pass

func _on_ai_state_changed(_new_state) -> void:
	"""Handle AI state changes (IDLE/PROCESSING/EXECUTING)"""
	_update_ui_from_state()
	pass

# ============================================================================
# Helper Methods
# ============================================================================

func _is_websocket_connected() -> bool:
	"""Check if WebSocket is connected"""
	if Main.has_node("AIWebSocketAdapter"):
		var adapter = Main.get_node("AIWebSocketAdapter")
		return adapter.is_server_connected()
	return false

func _get_ai_state():
	"""Get current AI state"""
	if Main.has_node("AIStateManager"):
		var state_mgr = Main.get_node("AIStateManager")
		return state_mgr.get_current_state()
	return null

func _get_selected_node_ids() -> Array:
	"""Get IDs of currently selected nodes on grid"""
	var selected_ids = []
	if Main.Mind:
		if Main.Mind.has_method("get_selected_nodes"):
			selected_ids = Main.Mind.get_selected_nodes()
	return selected_ids

func _get_current_scene_id() -> int:
	"""Get current scene ID"""
	if Main.Mind:
		if Main.Mind.has_method("get_current_open_scene_id"):
			return Main.Mind.get_current_open_scene_id()
	return -1

func _get_current_project_id() -> int:
	"""Get current project ID"""
	if Main.Mind and Main.Mind.ProMan:
		return Main.Mind.ProMan.get_active_project_id()
	return -1

func _is_valid_project_open() -> bool:
	"""Check if a valid named project is currently open"""
	if Main.Mind and Main.Mind.ProMan:
		return Main.Mind.ProMan.is_project_listed()
	return false

func _sync_project_file() -> void:
	"""Sync current project file to AI server"""
	if not _is_websocket_connected():
		return
	
	if Main.Mind and Main.Mind.has_method("get_project_content_json"):
		var project_content = Main.Mind.get_project_content_json()
		var project_id = _get_current_project_id()
		
		if Main.has_node("AIWebSocketAdapter"):
			var adapter = Main.get_node("AIWebSocketAdapter")
			adapter.send_file_sync(project_id, project_content)
			print("[AIChat] Project file synced to server")
	pass

# ============================================================================
# Project Change Notifications
# ============================================================================

func notify_project_opened() -> void:
	"""Called by Mind when a valid project is opened"""
	_update_ui_from_state()
	if _is_valid_project_open():
		append_anonymous_message("Connect to begin...")
	pass

func notify_project_closed() -> void:
	"""Called by Mind when project is closed (switches to blank)"""
	_update_ui_from_state()
	# append_system_message("Project closed. Open a named project to use AI features.")
	pass

# ============================================================================
# Panel Resize Functionality
# ============================================================================

func _process(_delta: float) -> void:
	"""Handle resize dragging"""
	if _is_resizing:
		var mouse_pos = get_viewport().get_mouse_position()
		var mouse_delta = mouse_pos.x - _resize_start_mouse_pos.x
		
		# Calculate new width (dragging left = wider panel, right = narrower)
		var new_width = _resize_start_panel_width - mouse_delta
		new_width = clamp(new_width, MIN_PANEL_WIDTH, MAX_PANEL_WIDTH)
		
		# Update panel width
		self.custom_minimum_size.x = new_width
		pass

func _on_resize_handle_input(event: InputEvent) -> void:
	"""Handle mouse input on the resize handle"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start resizing
				_is_resizing = true
				_resize_start_mouse_pos = get_viewport().get_mouse_position()
				_resize_start_panel_width = self.custom_minimum_size.x
			else:
				# Stop resizing
				_is_resizing = false
	
	elif event is InputEventMouseMotion and _is_resizing:
		# Cursor feedback during drag
		ResizeHandle.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	
	pass
