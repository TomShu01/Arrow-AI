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
	
	# AI WebSocket Adapter signals (if available in Main)
	if Main.has_node("AIWebSocketAdapter"):
		var adapter = Main.get_node("AIWebSocketAdapter")
		adapter.connection_state_changed.connect(self._on_connection_state_changed, CONNECT_DEFERRED)
		adapter.text_chunk_received.connect(self._on_text_chunk_received, CONNECT_DEFERRED)
		adapter.connection_error.connect(self._on_connection_error, CONNECT_DEFERRED)
	
	# AI State Manager signals (if available as singleton)
	if Main.has_node("AIStateManager"):
		var state_mgr = Main.get_node("AIStateManager")
		state_mgr.state_changed.connect(self._on_ai_state_changed, CONNECT_DEFERRED)
	
	pass

func _initialize_panel() -> void:
	# Set initial button states
	_update_ui_from_state()
	
	# Display welcome message only if valid project is open
	if _is_valid_project_open():
		append_system_message("AI Agent Ready. Connect to server to begin.")
	else:
		append_system_message("No project open. Open or create a named project to use AI features.")
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
		DisabledOverlay.set_visible(not is_valid_project)
	
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
	_add_message_to_chat("User", message, USER_MESSAGE_COLOR)
	_chat_history.append({"role": "user", "content": message})
	pass

func append_ai_message(message: String) -> void:
	"""Display complete AI message in chat"""
	_add_message_to_chat("AI", message, AI_MESSAGE_COLOR)
	_chat_history.append({"role": "assistant", "content": message})
	pass

func append_system_message(message: String) -> void:
	"""Display system message in chat"""
	_add_message_to_chat("System", message, SYSTEM_MESSAGE_COLOR)
	pass

func append_error_message(message: String) -> void:
	"""Display error message in chat"""
	_add_message_to_chat("Error", message, ERROR_MESSAGE_COLOR)
	pass

func _add_message_to_chat(sender: String, message: String, color: Color) -> void:
	"""Internal method to add formatted message to chat display"""
	# Create message container
	var message_box = VBoxContainer.new()
	message_box.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	
	# Create sender label
	var sender_label = Label.new()
	sender_label.set_text(sender + ":")
	sender_label.add_theme_color_override("font_color", color)
	sender_label.add_theme_font_size_override("font_size", 14)
	
	# Create message label
	var message_label = Label.new()
	message_label.set_text(message)
	for property in CHAT_MESSAGE_PROPERTIES:
		message_label.set(property, CHAT_MESSAGE_PROPERTIES[property])
	message_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Add to container
	message_box.add_child(sender_label)
	message_box.add_child(message_label)
	
	# Add spacer
	var spacer = Control.new()
	spacer.set_custom_minimum_size(Vector2(0, 10))
	message_box.add_child(spacer)
	
	# Add to chat
	ChatContainer.call_deferred("add_child", message_box)
	self.call_deferred("_update_scroll_to_max")
	pass

func start_streaming_ai_message() -> void:
	"""Begin accumulating a new streaming AI message"""
	_current_ai_message = ""
	pass

func append_ai_text_chunk(text: String) -> void:
	"""Add text chunk to current streaming AI message"""
	_current_ai_message += text
	# TODO: Update the last message in chat display with accumulated text
	# For now, we'll just accumulate and display when complete
	pass

func finish_streaming_ai_message() -> void:
	"""Complete the streaming AI message and display it"""
	if _current_ai_message.length() > 0:
		append_ai_message(_current_ai_message)
		_current_ai_message = ""
	pass

func clear_chat() -> void:
	"""Clear all chat messages"""
	for child in ChatContainer.get_children():
		child.queue_free()
	_chat_history.clear()
	_current_ai_message = ""
	append_system_message("Chat cleared.")
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
	
	# Send to server via WebSocket adapter
	if Main.has_node("AIWebSocketAdapter"):
		var adapter = Main.get_node("AIWebSocketAdapter")
		adapter.send_user_message(message, _chat_history, selected_nodes, current_scene_id, current_project_id)
		start_streaming_ai_message()
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
			# Get host and port from configuration (defaults if not found)
			var host = Main.Configs.CONFIRMED.get("ai_websocket_host", "localhost")
			var port = Main.Configs.CONFIRMED.get("ai_websocket_port", 8000)
			adapter.connect_to_server(host, port)
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
				append_system_message("Connected to AI server")
				# Sync project file on connection
				_sync_project_file()
			0:  # DISCONNECTED
				append_system_message("Disconnected from AI server")
			4:  # ERROR
				append_error_message("Connection error")
	pass

func _on_text_chunk_received(text: String) -> void:
	"""Handle streaming text chunks from AI"""
	append_ai_text_chunk(text)
	pass

func _on_connection_error(error_message: String) -> void:
	"""Handle WebSocket connection errors"""
	append_error_message("Connection error: " + error_message)
	pass

func _on_ai_state_changed(_new_state) -> void:
	"""Handle AI state changes (IDLE/PROCESSING/EXECUTING)"""
	_update_ui_from_state()
	
	# Complete streaming message when returning to IDLE
	if _new_state == 0:  # IDLE
		finish_streaming_ai_message()
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
		if Main.Mind.has_method("get_current_scene_id"):
			return Main.Mind.get_current_scene_id()
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
		append_system_message("Project opened. AI Agent ready.")
	pass

func notify_project_closed() -> void:
	"""Called by Mind when project is closed (switches to blank)"""
	_update_ui_from_state()
	append_system_message("Project closed. Open a named project to use AI features.")
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
