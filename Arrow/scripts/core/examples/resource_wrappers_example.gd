# Arrow Resource Wrappers - Usage Examples
# This file demonstrates how to use the intuitive wrapper functions for LLM/AI usage

extends RefCounted
class_name ResourceWrappersExample

# Example usage of the ResourceWrappers class
# mind parameter should be a CentralMind.Mind instance
func demonstrate_usage(mind):
	# Assuming you have access to the central mind
	var wrappers = ResourceWrappers.new(mind)
	
	# =============================================================================
	# NODE MANAGEMENT EXAMPLES
	# =============================================================================
	
	# Update a dialog node's content
	wrappers.update_node(
		123,
		"Welcome Dialog",
		{
			"character": 456,  # Character ID
			"lines": ["Hello, adventurer!", "Welcome to our world!"],
			"playable": true
		},
		"The first dialog players encounter"
	)
	
	# Update only the name of a node
	wrappers.update_node(124, "Updated Node Name")
	
	# Update only the data of a node
	wrappers.update_node(
		125,
		"",
		{
			"title": "New Title",
			"content": "Updated content"
		}
	)
	
	# Remove notes from a node
	wrappers.update_node(126, "", {}, "")
	
	# =============================================================================
	# VARIABLE MANAGEMENT EXAMPLES
	# =============================================================================
	
	# Update a variable's properties
	wrappers.update_variable(
		200,
		"player_health",
		"num",
		100,
		"Player's current health points"
	)
	
	# Update only the initial value
	wrappers.update_variable(201, "", "", 50)
	
	# Change variable type
	wrappers.update_variable(202, "", "str", "default_text")
	
	# =============================================================================
	# CHARACTER MANAGEMENT EXAMPLES
	# =============================================================================
	
	# Update a character's properties
	wrappers.update_character(
		300,
		"Hero",
		"00ff00",  # Green
		{
			"protagonist": true,
			"friendly": true
		},
		"The main character"
	)
	
	# Update only the color
	wrappers.update_character(301, "", "ff0000")  # Red
	
	# Add tags to a character
	wrappers.update_character(
		302,
		"",
		"",
		{
			"villain": true,
			"boss": true
		}
	)
	
	# =============================================================================
	# SCENE MANAGEMENT EXAMPLES
	# =============================================================================
	
	# Update a scene's properties
	wrappers.update_scene(
		400,
		"Main Story",
		123,  # Entry node ID
		false,
		"The main story scene"
	)
	
	# Update only the entry point
	wrappers.update_scene(401, "", 124)
	
	# Convert scene to macro
	wrappers.update_scene(402, "", -1, true, "", true)
	
	# =============================================================================
	# REMOVAL EXAMPLES
	# =============================================================================
	
	# Remove a node (will warn if it's being used)
	var success = wrappers.remove_node(123)
	if success:
		print("Node removed successfully")
	else:
		print("Failed to remove node (may be in use)")
	
	# Force remove a variable (ignores usage warnings)
	wrappers.remove_variable(200, true)
	
	# Remove a character
	wrappers.remove_character(300)
	
	# Remove a scene
	wrappers.remove_scene(400)
	
	# =============================================================================
	# QUERY EXAMPLES
	# =============================================================================
	
	# Get current data
	var node_data = wrappers.get_node_data(125)
	print("Node data: ", node_data)
	
	var variable_data = wrappers.get_variable_data(201)
	print("Variable data: ", variable_data)
	
	# List all resources
	var all_nodes = wrappers.list_all_nodes()
	var all_variables = wrappers.list_all_variables()
	var all_characters = wrappers.list_all_characters()
	var all_scenes = wrappers.list_all_scenes()
	
	print("Total nodes: ", all_nodes.size())
	print("Total variables: ", all_variables.size())
	print("Total characters: ", all_characters.size())
	print("Total scenes: ", all_scenes.size())
	
	# Find resources by name
	var found_node = wrappers.find_node_by_name("Welcome Dialog")
	if found_node.size() > 0:
		var node_id = found_node.keys()[0]
		print("Found node with ID: ", node_id)
	
	var found_variable = wrappers.find_variable_by_name("player_health")
	if found_variable.size() > 0:
		var var_id = found_variable.keys()[0]
		print("Found variable with ID: ", var_id)

# =============================================================================
# COMMON PATTERNS FOR LLM/AI USAGE
# =============================================================================

# Pattern 1: Create a complete dialog sequence
func create_dialog_sequence(wrappers: ResourceWrappers, character_id: int):
	# Update character
	wrappers.update_character(
		character_id,
		"NPC",
		"0080ff"
	)
	
	# Create dialog nodes (assuming they exist)
	wrappers.update_node(
		1001,
		"",
		{
			"character": character_id,
			"lines": ["Hello there!"],
			"playable": false
		}
	)
	
	wrappers.update_node(
		1002,
		"",
		{
			"character": character_id,
			"lines": ["How can I help you?"],
			"playable": false
		}
	)

# Pattern 2: Update game variables
func update_game_variables(wrappers: ResourceWrappers):
	wrappers.update_variable(
		2001,
		"score",
		"num",
		0
	)
	
	wrappers.update_variable(
		2002,
		"player_name",
		"str",
		"Player"
	)
	
	wrappers.update_variable(
		2003,
		"game_completed",
		"bool",
		false
	)

# Pattern 3: Scene management
func organize_scenes(wrappers: ResourceWrappers):
	# Update main scene
	wrappers.update_scene(
		5001,
		"Chapter 1",
		1001
	)
	
	# Update macro scene
	wrappers.update_scene(
		5002,
		"Combat System",
		2001,
		true,
		"",
		true
	)

# Pattern 4: Bulk operations
func bulk_update_nodes(wrappers: ResourceWrappers, node_updates: Array):
	for update in node_updates:
		wrappers.update_node(
			update.id,
			update.name,
			update.data,
			update.notes
		)

# Pattern 5: Error handling
func safe_update_node(wrappers: ResourceWrappers, node_id: int, data: Dictionary):
	# Check if node exists first
	var current_data = wrappers.get_node_data(node_id)
	if current_data.size() == 0:
		print("Error: Node ", node_id, " does not exist")
		return false
	
	# Update the node
	wrappers.update_node(node_id, "", data)
	print("Successfully updated node ", node_id)
	return true
