# State Manager helps you organize your interactive object
class_name StateManager

const DEFAULT: String = "default"

var states: Array[String] = [DEFAULT]
var current_state = DEFAULT
var owner: Node2D

func _init(owner_node: Node2D) -> void:
	owner = owner_node

func add_state(new_state: String) -> void:
	states.append(new_state)

func add_states(new_states: Array[String]) -> void:
	states.append_array(new_states)

func set_state(new_state: String) -> bool:
	if !states.has(new_state):
		printerr("State '%s' does not exist" % new_state)
		return false
	
	if current_state == new_state: return false
	
	var prev_state = current_state
	current_state = _change_state(new_state, prev_state)
	return prev_state != current_state


func _change_state(_new_state: String, _prev_state: String) -> String:
	# @PartiallyAbstract
	return _new_state
