# Arrow-AI
# Game Narrative Design Tool w/ AI
# Kushagra Sethi
#
# Resource Management Wrapper Functions
# Intuitive wrapper functions for LLM/AI usage of Arrow-AI resource management

extends RefCounted
class_name ResourceWrappers

# Core reference to the central mind
var _mind: Node

func _init(mind: Node):
	_mind = mind

# =============================================================================
# UPDATE WRAPPER FUNCTIONS
# =============================================================================

# Updates a node's properties
# Parameters:
# - node_id: The unique ID of the node to update
# - name: Optional new name for the node
# - data: Optional new data dictionary (type-specific content)
# - notes: Optional notes/description
# - is_auto_update: Whether this is an automatic update (prevents error messages)
func update_node(node_id: int, name: String = "", data: Dictionary = {}, notes: String = "", is_auto_update: bool = false) -> void:
	var modification = {}
	
	if name.length() > 0:
		modification["name"] = name
	
	if data.size() > 0:
		modification["data"] = data
	
	if notes.length() > 0:
		modification["notes"] = notes
	elif notes == "" and _mind._PROJECT.resources.nodes.has(node_id):
		# If notes is empty string, remove existing notes
		var current_node = _mind._PROJECT.resources.nodes[node_id]
		if current_node.has("notes"):
			modification["notes"] = null
	
	if modification.size() > 0:
		_mind.update_resource(node_id, modification, "nodes", is_auto_update)

# Updates a variable's properties
# Parameters:
# - variable_id: The unique ID of the variable to update
# - name: Optional new name for the variable
# - type: Optional new type ("num", "str", "bool")
# - initial_value: Optional new initial/default value
# - notes: Optional notes/description
func update_variable(variable_id: int, name: String = "", type: String = "", initial_value = null, notes: String = "") -> void:
	var modification = {}
	
	if name.length() > 0:
		modification["name"] = name
	
	if type.length() > 0 and type in ["num", "str", "bool"]:
		modification["type"] = type
	
	if initial_value != null:
		modification["init"] = initial_value
	
	if notes.length() > 0:
		modification["notes"] = notes
	elif notes == "" and _mind._PROJECT.resources.variables.has(variable_id):
		# If notes is empty string, remove existing notes
		var current_variable = _mind._PROJECT.resources.variables[variable_id]
		if current_variable.has("notes"):
			modification["notes"] = null
	
	if modification.size() > 0:
		_mind.update_resource(variable_id, modification, "variables")

# Updates a character's properties
# Parameters:
# - character_id: The unique ID of the character to update
# - name: Optional new name for the character
# - color: Optional new color (hex format, e.g., "ff0000" for red)
# - tags: Optional dictionary of character tags
# - notes: Optional notes/description
func update_character(character_id: int, name: String = "", color: String = "", tags: Dictionary = {}, notes: String = "") -> void:
	var modification = {}
	
	if name.length() > 0:
		modification["name"] = name
	
	if color.length() > 0:
		modification["color"] = color
	
	if tags.size() > 0:
		modification["tags"] = tags
	
	if notes.length() > 0:
		modification["notes"] = notes
	elif notes == "" and _mind._PROJECT.resources.characters.has(character_id):
		# If notes is empty string, remove existing notes
		var current_character = _mind._PROJECT.resources.characters[character_id]
		if current_character.has("notes"):
			modification["notes"] = null
	
	if modification.size() > 0:
		_mind.update_resource(character_id, modification, "characters")

# Updates a scene's properties
# Parameters:
# - scene_id: The unique ID of the scene to update
# - name: Optional new name for the scene
# - entry: Optional new entry node ID
# - macro: Optional boolean flag (for macro scenes)
# - notes: Optional notes/description
func update_scene(scene_id: int, name: String = "", entry: int = -1, macro: bool = false, notes: String = "", update_macro: bool = false) -> void:
	var modification = {}
	
	if name.length() > 0:
		modification["name"] = name
	
	if entry >= 0:
		modification["entry"] = entry
	
	if update_macro:
		modification["macro"] = macro
	
	if notes.length() > 0:
		modification["notes"] = notes
	elif notes == "" and _mind._PROJECT.resources.scenes.has(scene_id):
		# If notes is empty string, remove existing notes
		var current_scene = _mind._PROJECT.resources.scenes[scene_id]
		if current_scene.has("notes"):
			modification["notes"] = null
	
	if modification.size() > 0:
		_mind.update_resource(scene_id, modification, "scenes")

# =============================================================================
# REMOVE WRAPPER FUNCTIONS
# =============================================================================

# Removes a node from the project
# Parameters:
# - node_id: The unique ID of the node to remove
# - forced: Whether to force removal even if the node is being used
# Returns: true if successful, false otherwise
func remove_node(node_id: int, forced: bool = false) -> bool:
	return _mind.remove_resource(node_id, "nodes", forced)

# Removes a variable from the project
# Parameters:
# - variable_id: The unique ID of the variable to remove
# - forced: Whether to force removal even if the variable is being used
# Returns: true if successful, false otherwise
func remove_variable(variable_id: int, forced: bool = false) -> bool:
	return _mind.remove_resource(variable_id, "variables", forced)

# Removes a character from the project
# Parameters:
# - character_id: The unique ID of the character to remove
# - forced: Whether to force removal even if the character is being used
# Returns: true if successful, false otherwise
func remove_character(character_id: int, forced: bool = false) -> bool:
	return _mind.remove_resource(character_id, "characters", forced)

# Removes a scene from the project
# Parameters:
# - scene_id: The unique ID of the scene to remove
# - forced: Whether to force removal even if the scene is being used
# Returns: true if successful, false otherwise
func remove_scene(scene_id: int, forced: bool = false) -> bool:
	return _mind.remove_resource(scene_id, "scenes", forced)
