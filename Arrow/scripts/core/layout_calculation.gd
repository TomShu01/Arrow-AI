# Arrow-AI
# Game Narrative Design Tool w/ AI
# Kushagra Sethi
#
# Layout Calculation Functions
# Auto-spacing and layout management for Arrow-AI nodes

extends RefCounted
class_name LayoutCalculation

# Core reference to the central mind
var _mind: CentralMind.Mind

func _init(mind: CentralMind.Mind):
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
func auto_space_connected_nodes(node_id: int, _scene_id: int):
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
func apply_layout_to_scene(_scene_id: int, layout: Dictionary):
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
	
	# Analyze the existing layout to find patterns
	var layout_info = _analyze_scene_layout(scene_nodes)
	
	# Calculate position based on node type and existing layout
	match node_type:
		"entry":
			# Entry nodes go at the top-left
			return _calculate_entry_position(layout_info)
		"content", "dialog", "monolog":
			# Content/dialog nodes flow horizontally along the narrative path
			return _calculate_narrative_position(layout_info, node_type)
		"hub":
			# Hub nodes converge multiple paths
			return _calculate_hub_position(layout_info)
		"marker":
			# Markers go near the last node with some offset
			return _calculate_marker_position(layout_info)
		"jump":
			# Jump nodes go to the right of their source
			return _calculate_jump_position(layout_info)
		"condition", "tag_match", "tag_pass":
			# Conditional nodes for branching logic
			return _calculate_conditional_position(layout_info)
		"variable_update", "tag_edit":
			# Variable/tag operations positioned between narrative nodes
			return _calculate_operation_position(layout_info)
		_:
			# Default: place to the right with smart spacing
			return _calculate_default_position(layout_info)

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

# =============================================================================
# SMART AUTO-LAYOUT FUNCTIONS (FOR WEBSOCKET NODES)
# =============================================================================

# Analyzes the current scene layout to understand positioning patterns
func _analyze_scene_layout(scene_nodes: Array) -> Dictionary:
	var info = {
		"rightmost_position": Vector2(0, 0),
		"rightmost_node": null,
		"average_y": 100,
		"entry_position": Vector2(100, 100),
		"has_entry": false,
		"horizontal_spacing": [],
		"vertical_spacing": [],
		"flow_direction": Vector2.RIGHT,
		"nodes_by_row": {},  # Group nodes by approximate Y position
		"last_in_flow": null  # The last node in the main narrative flow
	}
	
	if scene_nodes.size() == 0:
		return info
	
	# Find rightmost node and collect spacing information
	var sum_y = 0
	var positions = []
	
	for node in scene_nodes:
		positions.append(node.position)
		sum_y += node.position.y
		
		if node.position.x > info.rightmost_position.x:
			info.rightmost_position = node.position
			info.rightmost_node = node
		
		if node.type == "entry":
			info.has_entry = true
			info.entry_position = node.position
	
	# Calculate average Y position
	if scene_nodes.size() > 0:
		info.average_y = sum_y / scene_nodes.size()
	
	# Calculate typical spacing by analyzing existing nodes
	positions.sort_custom(func(a, b): return a.x < b.x)
	for i in range(positions.size() - 1):
		var h_spacing = positions[i + 1].x - positions[i].x
		if h_spacing > 0:
			info.horizontal_spacing.append(h_spacing)
	
	# Sort by Y to find vertical spacing
	var positions_by_y = positions.duplicate()
	positions_by_y.sort_custom(func(a, b): return a.y < b.y)
	for i in range(positions_by_y.size() - 1):
		var v_spacing = positions_by_y[i + 1].y - positions_by_y[i].y
		if v_spacing > 0 and v_spacing < 300:  # Ignore large gaps
			info.vertical_spacing.append(v_spacing)
	
	# Find the last node in the main narrative flow (rightmost connected node)
	info.last_in_flow = _find_last_in_narrative_flow(scene_nodes)
	
	return info

# Finds the last node in the main narrative flow based on connections
func _find_last_in_narrative_flow(scene_nodes: Array) -> Dictionary:
	if scene_nodes.size() == 0:
		return {}
	
	# Build a graph of connections
	var outgoing_count = {}
	var incoming_count = {}
	
	for node in scene_nodes:
		outgoing_count[node.id] = 0
		incoming_count[node.id] = 0
		
		for connection in node.connections:
			if connection.size() >= 4:
				outgoing_count[node.id] += 1
	
	# Find nodes with no outgoing connections (potential end nodes)
	var end_nodes = []
	for node in scene_nodes:
		if outgoing_count[node.id] == 0:
			end_nodes.append(node)
	
	# Return the rightmost end node
	if end_nodes.size() > 0:
		end_nodes.sort_custom(func(a, b): return a.position.x > b.position.x)
		return end_nodes[0]
	
	# Fallback: return rightmost node
	var rightmost = scene_nodes[0]
	for node in scene_nodes:
		if node.position.x > rightmost.position.x:
			rightmost = node
	return rightmost

# Get typical horizontal spacing from layout analysis
func _get_typical_horizontal_spacing(layout_info: Dictionary) -> float:
	if layout_info.horizontal_spacing.size() > 0:
		var sum = 0
		for spacing in layout_info.horizontal_spacing:
			sum += spacing
		return sum / layout_info.horizontal_spacing.size()
	return 200.0  # Default spacing

# Get typical vertical spacing from layout analysis
func _get_typical_vertical_spacing(layout_info: Dictionary) -> float:
	if layout_info.vertical_spacing.size() > 0:
		var sum = 0
		for spacing in layout_info.vertical_spacing:
			sum += spacing
		return sum / layout_info.vertical_spacing.size()
	return 150.0  # Default spacing

# Calculate position for entry nodes
func _calculate_entry_position(layout_info: Dictionary) -> Vector2:
	if layout_info.has_entry:
		# Place near existing entry with vertical offset
		var v_spacing = _get_typical_vertical_spacing(layout_info)
		return layout_info.entry_position + Vector2(0, v_spacing)
	return Vector2(100, 100)

# Calculate position for narrative nodes (content, dialog, monolog)
func _calculate_narrative_position(layout_info: Dictionary, node_type: String) -> Vector2:
	var h_spacing = _get_typical_horizontal_spacing(layout_info)
	var _v_spacing = _get_typical_vertical_spacing(layout_info)
	
	# Use the last node in the narrative flow as reference
	if layout_info.last_in_flow != null and not layout_info.last_in_flow.is_empty():
		var last_pos = layout_info.last_in_flow.position
		
		# Different node types get slightly different spacing
		match node_type:
			"content":
				# Content nodes: larger horizontal spacing
				return last_pos + Vector2(h_spacing * 1.2, 0)
			"dialog", "monolog":
				# Dialog nodes: standard horizontal spacing
				return last_pos + Vector2(h_spacing, 0)
			_:
				return last_pos + Vector2(h_spacing, 0)
	
	# Fallback: place to the right of the rightmost node
	return layout_info.rightmost_position + Vector2(h_spacing, 0)

# Calculate position for hub nodes (convergence points)
func _calculate_hub_position(layout_info: Dictionary) -> Vector2:
	var h_spacing = _get_typical_horizontal_spacing(layout_info)
	var v_spacing = _get_typical_vertical_spacing(layout_info)
	
	# Hubs go to the right and slightly down
	return layout_info.rightmost_position + Vector2(h_spacing * 0.8, v_spacing * 0.3)

# Calculate position for marker nodes
func _calculate_marker_position(layout_info: Dictionary) -> Vector2:
	var h_spacing = _get_typical_horizontal_spacing(layout_info)
	var v_spacing = _get_typical_vertical_spacing(layout_info)
	
	# Markers go near the last node with offset
	return layout_info.rightmost_position + Vector2(h_spacing * 0.6, v_spacing * 0.4)

# Calculate position for jump nodes
func _calculate_jump_position(layout_info: Dictionary) -> Vector2:
	var h_spacing = _get_typical_horizontal_spacing(layout_info)
	
	# Jumps flow horizontally
	return layout_info.rightmost_position + Vector2(h_spacing, 0)

# Calculate position for conditional nodes (condition, tag_match, tag_pass)
func _calculate_conditional_position(layout_info: Dictionary) -> Vector2:
	var h_spacing = _get_typical_horizontal_spacing(layout_info)
	var v_spacing = _get_typical_vertical_spacing(layout_info)
	
	# Conditionals go to the right and slightly down to show branching
	return layout_info.rightmost_position + Vector2(h_spacing, v_spacing * 0.5)

# Calculate position for operation nodes (variable_update, tag_edit)
func _calculate_operation_position(layout_info: Dictionary) -> Vector2:
	var h_spacing = _get_typical_horizontal_spacing(layout_info)
	var v_spacing = _get_typical_vertical_spacing(layout_info)
	
	# Operations positioned slightly below the flow
	return layout_info.rightmost_position + Vector2(h_spacing * 0.7, v_spacing * 0.6)

# Calculate default position for unknown node types
func _calculate_default_position(layout_info: Dictionary) -> Vector2:
	var h_spacing = _get_typical_horizontal_spacing(layout_info)
	
	# Default: continue the horizontal flow
	return layout_info.rightmost_position + Vector2(h_spacing, 0)

# =============================================================================
# PUBLIC API FOR AUTO-LAYOUT FROM WEBSOCKET
# =============================================================================

# Calculate smart position for a new node being created from websocket
# This is the main entry point for auto-layout from the dispatcher
func calculate_smart_position_for_new_node(node_type: String, scene_id: int) -> Vector2:
	var scene_nodes = get_scene_nodes(scene_id)
	
	if scene_nodes.size() == 0:
		return Vector2(100, 100)
	
	# Analyze layout
	var layout_info = _analyze_scene_layout(scene_nodes)
	
	# Calculate position based on type
	match node_type:
		"entry":
			return _calculate_entry_position(layout_info)
		"content", "dialog", "monolog":
			return _calculate_narrative_position(layout_info, node_type)
		"hub":
			return _calculate_hub_position(layout_info)
		"marker":
			return _calculate_marker_position(layout_info)
		"jump":
			return _calculate_jump_position(layout_info)
		"condition", "tag_match", "tag_pass":
			return _calculate_conditional_position(layout_info)
		"variable_update", "tag_edit":
			return _calculate_operation_position(layout_info)
		_:
			return _calculate_default_position(layout_info)
