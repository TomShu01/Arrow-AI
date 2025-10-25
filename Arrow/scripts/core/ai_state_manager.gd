# Arrow-AI
# Game Narrative Design Tool w/ AI
# Kushagra Sethi

# AI State Manager
# Manages AI operation states and checkpoint tracking

class_name AIStateManager

enum AIState {
	IDLE,        # No AI operation
	PROCESSING,  # Server is thinking
	EXECUTING    # Commands being applied
}

var current_state: AIState = AIState.IDLE
var ai_operation_start_checkpoint_index: int = -1
var current_operation_request_id: String = ""

# Signals
signal state_changed(new_state: AIState)
signal operation_started(request_id: String)
signal operation_stopped()

func _init():
	pass

func is_idle() -> bool:
	return current_state == AIState.IDLE

func is_processing() -> bool:
	return current_state == AIState.PROCESSING

func is_executing() -> bool:
	return current_state == AIState.EXECUTING

func is_busy() -> bool:
	return current_state != AIState.IDLE

# Save checkpoint when transitioning from IDLE to PROCESSING
func save_operation_start_checkpoint(history_index: int) -> void:
	if current_state == AIState.IDLE:
		ai_operation_start_checkpoint_index = history_index
		print("AI State Manager: Saved checkpoint at history index ", history_index)

# Start AI operation (transition from IDLE to PROCESSING)
func start_operation(request_id: String, history_index: int) -> void:
	if current_state == AIState.IDLE:
		current_operation_request_id = request_id
		save_operation_start_checkpoint(history_index)
		current_state = AIState.PROCESSING
		state_changed.emit(current_state)
		operation_started.emit(request_id)
		print("AI State Manager: Operation started - ", request_id)
	else:
		printerr("AI State Manager: Cannot start operation, current state is ", current_state)

# Transition from PROCESSING to EXECUTING
func begin_execution() -> void:
	if current_state == AIState.PROCESSING:
		current_state = AIState.EXECUTING
		state_changed.emit(current_state)
		print("AI State Manager: State changed to EXECUTING")
	else:
		printerr("AI State Manager: Cannot begin execution, current state is ", current_state)

# End AI operation and return to IDLE
func end_operation() -> void:
	if current_state != AIState.IDLE:
		var was_idle = current_state == AIState.IDLE
		current_state = AIState.IDLE
		state_changed.emit(current_state)
		
		# Clear operation tracking
		if current_operation_request_id != "":
			print("AI State Manager: Operation ended - ", current_operation_request_id)
			current_operation_request_id = ""
		
		# Reset checkpoint index only if we're ending an operation
		if not was_idle and ai_operation_start_checkpoint_index != -1:
			print("AI State Manager: Checkpoint index cleared")
			ai_operation_start_checkpoint_index = -1
	else:
		print("AI State Manager: Already IDLE, cannot end operation")

# Handle stop signal (rollback to checkpoint)
func stop_operation() -> void:
	if current_state != AIState.IDLE:
		print("AI State Manager: Stop signal received, rolling back to checkpoint")
		current_operation_request_id = ""
		operation_stopped.emit()
		end_operation()

# Get saved checkpoint index for rollback
func get_saved_checkpoint_index() -> int:
	return ai_operation_start_checkpoint_index

# Check if checkpoint is saved
func has_saved_checkpoint() -> bool:
	return ai_operation_start_checkpoint_index != -1

# Get current operation request ID
func get_current_request_id() -> String:
	return current_operation_request_id

# Get state name as string for debugging
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
