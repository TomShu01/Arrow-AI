# Arrow-AI
# Game Narrative Design Tool w/ AI
# Kushagra Sethi
#
# Layout Calculation Functions
# Auto-spacing and layout management for Arrow-AI nodes

extends RefCounted
class_name LayoutCalculation

# Core reference to the central mind
var _mind: Node

func _init(mind: Node):
	_mind = mind

# =============================================================================
# AUTO-SPACING FUNCTIONS
# =============================================================================

# Auto-spacing logic for new nodes
func auto_space_new_node(node_id: int, scene_id: int):
	var scene_nodes = get_scene_nodes(scene_id)
	var new_position = calculate_optimal_position(node_id, scene_nodes)
	update_node_position(node_id, new_position)

# Auto-spacing logic for connected nodes
func auto_space_connected_nodes(node_id: int, scene_id: int):
	var connected_nodes = get_connected_nodes(node_id)
	var positions = calculate_flow_layout(connected_nodes)
	for node in connected_nodes:
		update_node_position(node.id, positions[node.id])

# Auto-spacing logic for entire scene
func auto_space_scene(scene_id: int):
	var scene_nodes = get_scene_nodes(scene_id)
	var layout = calculate_scene_layout(scene_nodes)
	apply_layout_to_scene(scene_id, layout)

# =============================================================================
# HELPER FUNCTIONS FOR AUTO-SPACING
# =============================================================================

# Gets all nodes in a scene
func get_scene_nodes(scene_id: int) -> Array:
	var scene_nodes = []
	if _mind._PROJECT.resources.scenes.has(scene_id):
		var scene = _mind._PROJECT.resources.scenes[scene_id]
		if scene.has("map"):
			for node_id_str in scene.map.keys():
				var node_id = int(node_id_str)
				if _mind._PROJECT.resources.nodes.has(node_id):
					var node = _mind._PROJECT.resources.nodes[node_id]
					var position = Vector2.ZERO
					if scene.map[node_id_str].has("offset"):
						position = Vector2(scene.map[node_id_str].offset[0], scene.map[node_id_str].offset[1])
					scene_nodes.append({
						"id": node_id,
						"type": node.type,
						"position": position,
						"connections": get_node_connections(node_id, scene_id)
					})
	return scene_nodes

# Gets connections for a specific node in a scene
func get_node_connections(node_id: int, scene_id: int) -> Array:
	var connections = []
	if _mind._PROJECT.resources.scenes.has(scene_id):
		var scene = _mind._PROJECT.resources.scenes[scene_id]
		if scene.has("map") and scene.map.has(str(node_id)):
			var node_map = scene.map[str(node_id)]
			if node_map.has("io"):
				connections = node_map.io
	return connections

# Updates node position in the project
func update_node_position(node_id: int, position: Vector2):
	if _mind._PROJECT.resources.scenes.has(_mind._CURRENT_OPEN_SCENE_ID):
		var scene_id = _mind._CURRENT_OPEN_SCENE_ID
		var modification = {
			"offset": [position.x, position.y]
		}
		_mind.update_node_map(node_id, modification, scene_id)

# Gets connected nodes for a given node
func get_connected_nodes(node_id: int) -> Array:
	var connected_nodes = []
	var scene_id = _mind._CURRENT_OPEN_SCENE_ID
	var connections = get_node_connections(node_id, scene_id)
	
	for connection in connections:
		if connection.size() >= 4:
			var from_id = connection[0]
			var to_id = connection[2]
			
			# Add outgoing connections
			if from_id == node_id and _mind._PROJECT.resources.nodes.has(to_id):
				connected_nodes.append({
					"id": to_id,
					"type": _mind._PROJECT.resources.nodes[to_id].type,
					"direction": "outgoing"
				})
			
			# Add incoming connections
			if to_id == node_id and _mind._PROJECT.resources.nodes.has(from_id):
				connected_nodes.append({
					"id": from_id,
					"type": _mind._PROJECT.resources.nodes[from_id].type,
					"direction": "incoming"
				})
	
	return connected_nodes

# Applies layout to entire scene
func apply_layout_to_scene(scene_id: int, layout: Dictionary):
	for node_id in layout.keys():
		update_node_position(node_id, layout[node_id])

# =============================================================================
# POSITION CALCULATION FUNCTIONS
# =============================================================================

# Calculates optimal position for a new node
func calculate_optimal_position(node_id: int, scene_nodes: Array) -> Vector2:
	if scene_nodes.size() == 0:
		return Vector2(100, 100)  # Default starting position
	
	var node_type = _mind._PROJECT.resources.nodes[node_id].type
	var base_position = Vector2(100, 100)
	var spacing = Vector2(200, 150)
	
	# Find the rightmost node to place new node to its right
	var rightmost_x = 0
	var rightmost_y = 0
	
	for node in scene_nodes:
		if node.position.x > rightmost_x:
			rightmost_x = node.position.x
			rightmost_y = node.position.y
	
	# Calculate position based on node type
	match node_type:
		"entry":
			# Entry nodes go at the top-left
			return Vector2(100, 100)
		"content", "dialog", "monolog":
			# Content nodes flow horizontally
			return Vector2(rightmost_x + spacing.x, rightmost_y)
		"hub":
			# Hub nodes go below their input nodes
			return Vector2(rightmost_x, rightmost_y + spacing.y)
		"marker":
			# Markers go near their related nodes
			return Vector2(rightmost_x + spacing.x * 0.5, rightmost_y + spacing.y * 0.5)
		"jump":
			# Jump nodes go to the right of their source
			return Vector2(rightmost_x + spacing.x, rightmost_y)
		_:
			# Default: place to the right
			return Vector2(rightmost_x + spacing.x, rightmost_y)

# Calculates flow layout for connected nodes
func calculate_flow_layout(connected_nodes: Array) -> Dictionary:
	var positions = {}
	var spacing = Vector2(200, 150)
	var base_position = Vector2(100, 100)
	
	# Group nodes by direction
	var incoming_nodes = []
	var outgoing_nodes = []
	
	for node in connected_nodes:
		if node.direction == "incoming":
			incoming_nodes.append(node)
		else:
			outgoing_nodes.append(node)
	
	# Position incoming nodes to the left
	for i in range(incoming_nodes.size()):
		var node = incoming_nodes[i]
		positions[node.id] = Vector2(base_position.x - spacing.x, base_position.y + i * spacing.y)
	
	# Position outgoing nodes to the right
	for i in range(outgoing_nodes.size()):
		var node = outgoing_nodes[i]
		positions[node.id] = Vector2(base_position.x + spacing.x, base_position.y + i * spacing.y)
	
	return positions

# Calculates layout for entire scene
func calculate_scene_layout(scene_nodes: Array) -> Dictionary:
	var positions = {}
	var spacing = Vector2(200, 150)
	var start_position = Vector2(100, 100)
	
	# Group nodes by type for better organization
	var entry_nodes = []
	var content_nodes = []
	var dialog_nodes = []
	var hub_nodes = []
	var marker_nodes = []
	var other_nodes = []
	
	for node in scene_nodes:
		match node.type:
			"entry":
				entry_nodes.append(node)
			"content":
				content_nodes.append(node)
			"dialog", "monolog":
				dialog_nodes.append(node)
			"hub":
				hub_nodes.append(node)
			"marker":
				marker_nodes.append(node)
			_:
				other_nodes.append(node)
	
	# Position entry nodes at the top
	for i in range(entry_nodes.size()):
		positions[entry_nodes[i].id] = Vector2(start_position.x, start_position.y + i * spacing.y)
	
	# Position content nodes in a horizontal flow
	var content_y = start_position.y + entry_nodes.size() * spacing.y + spacing.y
	for i in range(content_nodes.size()):
		positions[content_nodes[i].id] = Vector2(start_position.x + i * spacing.x, content_y)
	
	# Position dialog nodes below content
	var dialog_y = content_y + spacing.y
	for i in range(dialog_nodes.size()):
		positions[dialog_nodes[i].id] = Vector2(start_position.x + i * spacing.x, dialog_y)
	
	# Position hub nodes below dialog
	var hub_y = dialog_y + spacing.y
	for i in range(hub_nodes.size()):
		positions[hub_nodes[i].id] = Vector2(start_position.x + i * spacing.x, hub_y)
	
	# Position marker nodes in a separate column
	var marker_x = start_position.x + max(content_nodes.size(), dialog_nodes.size(), hub_nodes.size()) * spacing.x + spacing.x
	for i in range(marker_nodes.size()):
		positions[marker_nodes[i].id] = Vector2(marker_x, start_position.y + i * spacing.y)
	
	# Position other nodes at the bottom
	var other_y = hub_y + spacing.y
	for i in range(other_nodes.size()):
		positions[other_nodes[i].id] = Vector2(start_position.x + i * spacing.x, other_y)
	
	return positions

# Helper function to get maximum of three values
func max(a: int, b: int, c: int) -> int:
	return max(max(a, b), c)
