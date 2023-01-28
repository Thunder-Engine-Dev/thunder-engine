extends StateManager
class_name PlayerStatesManager

var jump_buffer: bool = false
var left_or_right:int
var dir: int = 1


func _init(owner_node: Node2D) -> void:
	super(owner_node)
	add_states([
		"jump",
		"crouch",
		"swim",
		"climb",
		"dead",
		"static"
	])


func _change_state(_new_state: String, _prev_state: String) -> String:
	if _prev_state == "dead": return _prev_state
	
	if _new_state == "jump":
		match _prev_state:
			"crouch": return _prev_state
			"swim": return _prev_state
	
	#if _new_state == "":
	#	match _prev_state:
	#		"crouch": return _prev_state
	#		"swim": return _prev_state
	
	return _new_state

func update_states() -> void:
	_update_animations()
	
	if current_state == "jump" && owner.is_on_floor():
		set_state("default")
	
	if !owner.is_on_floor() && current_state == "default":
		set_state("jump")
		

func _update_animations() -> void:
	var size = owner.sprite.sprite_frames.get_frame_texture(owner.sprite.animation, owner.sprite.frame).get_size()
	owner.sprite.offset.y = -size.y
	owner.sprite.offset.x = -size.x / 2
	
	owner.sprite.animation = current_state
	if current_state == "default":
		owner.sprite.speed_scale = abs(owner.velocity_local.x / 50) * 2.5 + 4
	else:
		owner.sprite.speed_scale = 1
	
	if owner.velocity_local.x == 0:
		owner.sprite.frame = owner.sprite.sprite_frames.get_frame_count(current_state) - 1
		owner.sprite.speed_scale = 0
	
	if owner.velocity_local.x > 0:
		owner.sprite.flip_h = false
	if owner.velocity_local.x < 0:
		owner.sprite.flip_h = true
