# Arrow-AI
# Game Narrative Design Tool w/ AI
# Kushagra Sethi

# AI Command Dispatcher
# Executes function calls received from the AI server and sends results back
# Handles saving project after successful execution and embedding arrow_content

class_name AICommandDispatcher
extends Node

# References (set by Main)
var _mind: CentralMind.Mind = null
var _adapter: AIWebSocketAdapter = null
var _state_manager: AIStateManager = null

# Signals
signal command_executed(request_id: String, success: bool)
signal command_failed(request_id: String, error: String)

func _init():
	pass

func initialize(mind: CentralMind.Mind, adapter: AIWebSocketAdapter, state_mgr: AIStateManager) -> void:
	"""Initialize dispatcher with required references"""
	_mind = mind
	_adapter = adapter
	_state_manager = state_mgr
	
	# Connect to adapter's function_call signal
	if _adapter:
		_adapter.function_call_received.connect(_on_function_call_received)
	
	print("[AICommandDispatcher] Initialized")

# ============================================================================
# Command Execution
# ============================================================================

func _on_function_call_received(request_id: String, function_name: String, args: Dictionary) -> void:
	"""Handle incoming function call from server"""
	print("[AICommandDispatcher] Executing: ", function_name, " (", request_id, ")")
	
	# Transition to EXECUTING state
	if _state_manager and _state_manager.is_ai_processing():
		_state_manager.begin_execution()
	
	# Execute the function
	var result = _execute_function(function_name, args)
	
	if result.success:
		# Save project after successful execution
		_save_project_after_command()
		
		# Read arrow content and send result
		var arrow_content = _read_arrow_content()
		_adapter.send_function_result(request_id, true, result.value, "", arrow_content, {})
		
		command_executed.emit(request_id, true)
		print("[AICommandDispatcher] Success: ", function_name)
	else:
		# Rollback one step on error
		_rollback_one_step()
		
		# Send error result (no arrow_content since we rolled back)
		_adapter.send_function_result(request_id, false, null, result.error, "", result.affected_nodes)
		
		command_failed.emit(request_id, result.error)
		printerr("[AICommandDispatcher] Error in ", function_name, ": ", result.error)

func _execute_function(function_name: String, args: Dictionary) -> Dictionary:
	"""
	Execute a Mind function with provided arguments
	Returns: { success: bool, value: any, error: String, affected_nodes: Dictionary }
	"""
	if not _mind:
		return _error_result("Mind reference not initialized")
	
	var result = { "success": false, "value": null, "error": "", "affected_nodes": {} }
	
	# Execute the function with validation
	match function_name:
			# ===== NODE OPERATIONS =====
			"create_insert_node":
				# Validate required parameters
				if not args.has("type") or args.get("type", "") == "":
					result.error = "Missing required parameter: type"
					return result
				
				var node_id = _mind.create_insert_node(
					args.get("type", ""),
					args.get("offset", Vector2.ZERO),
					args.get("scene_id", -1),
					args.get("draw", true),
					args.get("name_prefix", ""),
					args.get("preset", {})
				)
				
				# Validate node was created successfully
				if node_id < 0:
					result.error = "Failed to create node (invalid node_id returned)"
					return result
				
				result.success = true
				result.value = node_id
			
			"quick_insert_node":
				# Validate required parameters
				if not args.has("node_type") or args.get("node_type", "") == "":
					result.error = "Missing required parameter: node_type"
					return result
				
				_mind.quick_insert_node(
					args.get("node_type", ""),
					args.get("offset", Vector2.ZERO),
					args.get("connection", null)
				)
				result.success = true
				result.value = "Node inserted successfully"
			
			"update_node":
				# Validate required parameters
				if not args.has("node_id") or args.get("node_id", -1) < 0:
					result.error = "Missing or invalid required parameter: node_id"
					return result
				
				_mind.update_node(
					args.get("node_id", -1),
					args.get("name", ""),
					args.get("data", {}),
					args.get("notes", ""),
					args.get("is_auto_update", false)
				)
				result.success = true
				result.value = "Node updated successfully"
			
			"remove_node":
				# Validate required parameters
				if not args.has("node_id") or args.get("node_id", -1) < 0:
					result.error = "Missing or invalid required parameter: node_id"
					return result
				
				var removed = _mind.remove_node(
					args.get("node_id", -1),
					args.get("forced", false)
				)
				result.success = true
				result.value = removed
			
			"update_node_map":
				# Validate required parameters
				if not args.has("node_id") or args.get("node_id", -1) < 0:
					result.error = "Missing or invalid required parameter: node_id"
					return result
				if not args.has("modification"):
					result.error = "Missing required parameter: modification"
					return result
				
				_mind.update_node_map(
					args.get("node_id", -1),
					args.get("modification", {}),
					args.get("scene_id", -1)
				)
				result.success = true
				result.value = "Node map updated successfully"
			
			# ===== SCENE OPERATIONS =====
			"create_new_scene":
				_mind.create_new_scene(
					args.get("is_macro", false)
				)
				result.success = true
				result.value = "Scene created successfully"
			
			"update_scene":
				# Validate required parameters
				if not args.has("scene_id") or args.get("scene_id", -1) < 0:
					result.error = "Missing or invalid required parameter: scene_id"
					return result
				
				_mind.update_scene(
					args.get("scene_id", -1),
					args.get("name", ""),
					args.get("entry", -1),
					args.get("macro", null),
					args.get("notes", "")
				)
				result.success = true
				result.value = "Scene updated successfully"
			
			"remove_scene":
				# Validate required parameters
				if not args.has("scene_id") or args.get("scene_id", -1) < 0:
					result.error = "Missing or invalid required parameter: scene_id"
					return result
				
				var removed = _mind.remove_scene(
					args.get("scene_id", -1),
					args.get("forced", false)
				)
				result.success = true
				result.value = removed
			
			# ===== VARIABLE OPERATIONS =====
			"create_new_variable":
				# Validate required parameters
				if not args.has("type") or args.get("type", "") == "":
					result.error = "Missing required parameter: type"
					return result
				
				_mind.create_new_variable(
					args.get("type", "")
				)
				result.success = true
				result.value = "Variable created successfully"
			
			"update_variable":
				# Validate required parameters
				if not args.has("variable_id") or args.get("variable_id", -1) < 0:
					result.error = "Missing or invalid required parameter: variable_id"
					return result
				
				_mind.update_variable(
					args.get("variable_id", -1),
					args.get("name", ""),
					args.get("type", ""),
					args.get("initial_value", null),
					args.get("notes", "")
				)
				result.success = true
				result.value = "Variable updated successfully"
			
			"remove_variable":
				# Validate required parameters
				if not args.has("variable_id") or args.get("variable_id", -1) < 0:
					result.error = "Missing or invalid required parameter: variable_id"
					return result
				
				var removed = _mind.remove_variable(
					args.get("variable_id", -1),
					args.get("forced", false)
				)
				result.success = true
				result.value = removed
			
			# ===== CHARACTER OPERATIONS =====
			"create_new_character":
				_mind.create_new_character()
				result.success = true
				result.value = "Character created successfully"
			
			"update_character":
				# Validate required parameters
				if not args.has("character_id") or args.get("character_id", -1) < 0:
					result.error = "Missing or invalid required parameter: character_id"
					return result
				
				_mind.update_character(
					args.get("character_id", -1),
					args.get("name", ""),
					args.get("color", ""),
					args.get("tags", {}),
					args.get("notes", "")
				)
				result.success = true
				result.value = "Character updated successfully"
			
			"remove_character":
				# Validate required parameters
				if not args.has("character_id") or args.get("character_id", -1) < 0:
					result.error = "Missing or invalid required parameter: character_id"
					return result
				
				var removed = _mind.remove_character(
					args.get("character_id", -1),
					args.get("forced", false)
				)
				result.success = true
				result.value = removed
			
			# ===== UTILITY OPERATIONS =====
			"node_connection_replacement":
				# Validate required parameters
				if not args.has("conversation_table"):
					result.error = "Missing required parameter: conversation_table"
					return result
				
				var replaced = _mind.node_connection_replacement(
					args.get("conversation_table", {}),
					args.get("remake_lost_connections", true)
				)
				result.success = true
				result.value = replaced
			
			# ===== ENTRY POINT OPERATIONS =====
			"update_scene_entry":
				# Validate required parameters
				if not args.has("node_id") or args.get("node_id", -1) < 0:
					result.error = "Missing or invalid required parameter: node_id"
					return result
				
				var entry_id = _mind.update_scene_entry(
					args.get("node_id", -1)
				)
				result.success = true
				result.value = entry_id
			
			"update_project_entry":
				# Validate required parameters
				if not args.has("node_id") or args.get("node_id", -1) < 0:
					result.error = "Missing or invalid required parameter: node_id"
					return result
				
				var entry_id = _mind.update_project_entry(
					args.get("node_id", -1)
				)
				result.success = true
				result.value = entry_id
			
			_:
				result.error = "Unknown function: " + function_name
	
	return result

func _error_result(error_message: String) -> Dictionary:
	"""Helper to create error result"""
	return {
		"success": false,
		"value": null,
		"error": error_message,
		"affected_nodes": {}
	}

# ============================================================================
# Project State Management
# ============================================================================

func _save_project_after_command() -> void:
	"""Save project after successful command execution"""
	if not _mind:
		printerr("[AICommandDispatcher] Cannot save project: Mind reference not initialized")
		return
	
	# Call Mind's save_project function
	_mind.save_project()
	print("[AICommandDispatcher] Project saved after command execution")

func _read_arrow_content() -> String:
	"""
	Read the current .arrow project file content as a JSON string
	Returns empty string if unable to read
	"""
	if not _mind or not _mind.ProMan:
		printerr("[AICommandDispatcher] Cannot read arrow content: ProMan not available")
		return ""
	
	# Get project file path
	var project_id = _mind.ProMan.get_active_project_id()
	if project_id < 0:
		printerr("[AICommandDispatcher] No active project to read")
		return ""
	
	var project_path = _mind.ProMan.get_project_file_path(project_id)
	if not project_path or project_path == "":
		printerr("[AICommandDispatcher] Invalid project path")
		return ""
	
	# Read file content
	if not FileAccess.file_exists(project_path):
		printerr("[AICommandDispatcher] Project file does not exist: ", project_path)
		return ""
	
	var file = FileAccess.open(project_path, FileAccess.READ)
	if not file:
		printerr("[AICommandDispatcher] Cannot open project file: ", project_path)
		return ""
	
	var content = file.get_as_text()
	file.close()
	
	print("[AICommandDispatcher] Read arrow content (", content.length(), " bytes)")
	return content

func _rollback_one_step() -> void:
	"""Rollback project state by one step in history"""
	if not _mind:
		printerr("[AICommandDispatcher] Cannot rollback: Mind reference not initialized")
		return
	
	# Use Mind's undo functionality to rollback one step
	if _mind.has_method("undo"):
		_mind.undo()
		print("[AICommandDispatcher] Rolled back one step after error")
	else:
		printerr("[AICommandDispatcher] Mind does not have undo method")

# ============================================================================
# Utility Functions
# ============================================================================

func is_initialized() -> bool:
	"""Check if dispatcher is properly initialized"""
	return _mind != null and _adapter != null and _state_manager != null

