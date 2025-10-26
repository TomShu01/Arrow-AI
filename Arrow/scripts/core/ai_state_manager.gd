# Arrow-AI
# Game Narrative Design Tool w/ AI
# Kushagra Sethi

# AI State Manager
# Manages AI operation states and checkpoint tracking for rollback functionality
# State flow: IDLE -> PROCESSING -> EXECUTING -> IDLE

class_name AIStateManager
extends Node

# AI operation states
enum AIState {
	IDLE,        # No AI operation in progress
	PROCESSING,  # Server is thinking/planning
	EXECUTING    # Commands are being applied to the project
}

# State tracking
var current_state: AIState = AIState.IDLE

# Checkpoint tracking for rollback on stop signal
var ai_operation_start_checkpoint_index: int = -1

# Current operation tracking
var current_operation_request_id: String = ""

# Signals
signal state_changed(new_state: AIState)
signal operation_started(request_id: String)
signal operation_stopped()

func _init():
	pass

# ============================================================================
# State Query Functions
# ============================================================================

func is_ai_idle() -> bool:
	return current_state == AIState.IDLE

func is_ai_processing() -> bool:
	return current_state == AIState.PROCESSING

func is_ai_executing() -> bool:
	return current_state == AIState.EXECUTING

func is_ai_busy() -> bool:
	return current_state != AIState.IDLE

func get_current_state() -> AIState:
	return current_state

func get_state_name() -> String:
	match current_state:
		AIState.IDLE:
			return "IDLE"
		AIState.PROCESSING:
			return "PROCESSING"
		AIState.EXECUTING:
			return "EXECUTING"
		_:
			return "UNKNOWN"

# ============================================================================
# State Transition Functions
# ============================================================================

# Start AI operation: IDLE -> PROCESSING
# Saves checkpoint at current history index for potential rollback
func start_operation(request_id: String, history_index: int) -> void:
	if not is_ai_idle():
		printerr("AI State Manager: Cannot start operation, current state is ", get_state_name())
		return
	
	# Save checkpoint for rollback
	ai_operation_start_checkpoint_index = history_index
	current_operation_request_id = request_id
	
	# Transition to PROCESSING state
	current_state = AIState.PROCESSING
	state_changed.emit(current_state)
	operation_started.emit(request_id)
	
	print("AI State Manager: Operation started (", request_id, ") - Checkpoint saved at index ", history_index)

# Begin command execution: PROCESSING -> EXECUTING
func begin_execution() -> void:
	if not is_ai_processing():
		printerr("AI State Manager: Cannot begin execution from state ", get_state_name())
		return
	
	current_state = AIState.EXECUTING
	state_changed.emit(current_state)
	print("AI State Manager: State changed to EXECUTING")

# End AI operation: PROCESSING/EXECUTING -> IDLE
# Clears checkpoint and operation tracking
func end_operation() -> void:
	if is_ai_idle():
		print("AI State Manager: Already IDLE, no operation to end")
		return
	
	var previous_state = get_state_name()
	var previous_request_id = current_operation_request_id
	
	# Transition to IDLE
	current_state = AIState.IDLE
	state_changed.emit(current_state)
	
	# Clear operation tracking
	current_operation_request_id = ""
	ai_operation_start_checkpoint_index = -1
	
	print("AI State Manager: Operation ended (", previous_request_id, ") - Previous state: ", previous_state)

# Stop operation and request rollback: ANY -> IDLE
# Emits operation_stopped signal for rollback handling
func stop_operation() -> void:
	if is_ai_idle():
		print("AI State Manager: No operation to stop (already IDLE)")
		return
	
	print("AI State Manager: Stop signal received - Checkpoint: ", ai_operation_start_checkpoint_index)
	
	# Emit stop signal before state change (handlers may need current state)
	operation_stopped.emit()
	
	# Clear tracking and transition to IDLE
	current_operation_request_id = ""
	current_state = AIState.IDLE
	state_changed.emit(current_state)
	
	# Note: checkpoint index is NOT cleared here, as rollback handler needs it
	print("AI State Manager: Operation stopped - Rollback should be handled by listener")

# ============================================================================
# Checkpoint Management
# ============================================================================

# Get saved checkpoint index for rollback
func get_saved_checkpoint_index() -> int:
	return ai_operation_start_checkpoint_index

# Check if a valid checkpoint is saved
func has_saved_checkpoint() -> bool:
	return ai_operation_start_checkpoint_index != -1

# Clear saved checkpoint (call after successful rollback)
func clear_checkpoint() -> void:
	if ai_operation_start_checkpoint_index != -1:
		print("AI State Manager: Checkpoint cleared (was at index ", ai_operation_start_checkpoint_index, ")")
		ai_operation_start_checkpoint_index = -1

# ============================================================================
# Operation Tracking
# ============================================================================

# Get current operation request ID
func get_current_request_id() -> String:
	return current_operation_request_id

# Check if an operation is currently tracked
func has_active_operation() -> bool:
	return current_operation_request_id != ""
