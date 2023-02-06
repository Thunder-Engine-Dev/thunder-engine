extends StateManager
class_name PlayerStatesManager

var jump_buffer: bool = false
var left_or_right: int
var dir: int = 1

var projectiles_count: int = 2

var invincible_timer: float = 0
var appear_timer: float = 0
var launch_timer: float = 0

func _init(owner_node: Node2D) -> void:
	super(owner_node)
	add_states([
		"jump",
		"crouch",
		"swim",
		"climb",
		"dead",
		"static",
		"stuck"
	])


func _change_state(_new_state: String, _prev_state: String) -> String:
	if _prev_state == "dead": return _prev_state
	
	if _new_state == "jump":
		match _prev_state:
			"swim": return _prev_state
	
	if _new_state == "crouch":
		match _prev_state:
			"jump": return _prev_state
			"swim": return _prev_state
			_:
				owner.update_collisions(Thunder._current_player_state, true)
	
	if _prev_state == "crouch":
		if owner.update_collisions(Thunder._current_player_state, false):
			return "stuck"
	
	#if _new_state == "":
	#	match _prev_state:
	#		"crouch": return _prev_state
	#		"swim": return _prev_state
	
	return _new_state

func update_states(delta: float) -> void:
	if current_state == "jump" && owner.is_on_floor():
		set_state("default")
	
	if !owner.is_on_floor() && (current_state == "default" || current_state == "crouch"):
		set_state("jump")
	
	if invincible_timer > 0:
		invincible_timer = max(invincible_timer - delta, 0)
	if appear_timer > 0:
		appear_timer = max(appear_timer - delta, 0)
	if launch_timer > 0:
		launch_timer = max(launch_timer - delta, 0)
	
	_update_animations()

func _update_animations() -> void:
	if !is_instance_valid(owner.sprite.sprite_frames):
		return
	
	if appear_timer == 0 && launch_timer == 0:
		if current_state == "stuck":
			owner.sprite.set_animation("default")
			owner.sprite.frame = owner.sprite.sprite_frames.get_frame_count("default") - 1
			owner.sprite.speed_scale = 0
			return
		
		if !_set_animation(current_state):
			return
		
		if current_state == "default":
			owner.sprite.speed_scale = abs(owner.velocity_local.x / Thunder._target_speed) * 2.5 + 4
		else:
			owner.sprite.speed_scale = 1
		
		if owner.velocity_local.x == 0:
			owner.sprite.frame = owner.sprite.sprite_frames.get_frame_count(current_state) - 1
			owner.sprite.speed_scale = 0
			owner.sprite.frame_progress = 1.0
	elif launch_timer > 0:
		appear_timer = 0
		owner.sprite.animation = "launch"
		owner.sprite.speed_scale = 1
	elif appear_timer > 0:
		owner.sprite.animation = "appear"
		owner.sprite.speed_scale = 1
	
	if invincible_timer > 0 && appear_timer == 0:
		owner.sprite.visible = int(invincible_timer * 1.5 / 2) % 2 == 0
	else:
		owner.sprite.visible = true
	
	if owner.velocity_local.x > 0:
		owner.sprite.flip_h = false
	if owner.velocity_local.x < 0:
		owner.sprite.flip_h = true
	
	var size = owner.sprite.sprite_frames.get_frame_texture(owner.sprite.animation, owner.sprite.frame).get_size()
	owner.sprite.offset.y = -size.y
	owner.sprite.offset.x = -size.x / 2

func _set_animation(animation) -> bool:
	if owner.sprite.sprite_frames.has_animation(animation):
		owner.sprite.animation = animation
	else:
		push_error("[PlayerStateManager] Invalid animation '" + animation + "'")
		return false
	return true
