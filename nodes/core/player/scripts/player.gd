@tool
extends CorrectedCharacterBody2D
class_name Player

@export var config: PlayerConfiguration = PlayerConfiguration.new()
@export var custom_script: Script
@export var default_player_state: PlayerStateData = PlayerStateData.new()

var states: PlayerStatesManager = PlayerStatesManager.new(self)
var extra_script: Script
var powerup_script: Script
var velocity_local: Vector2

@onready var sprite: Node2D = $Sprite
@onready var sprite_no_img: Node2D = $SpriteNoImg
@onready var shape_small: CollisionShape2D = $CollisionSmall
@onready var shape_big: CollisionShape2D = $CollisionBig
@onready var stomping_cast: ShapeCast2D = $StompingCast


func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	extra_script = ByNodeScript.activate_script(custom_script, self)
	
	Thunder._current_player = self
	
	if !Thunder._current_player_state:
		Thunder._current_player_state = default_player_state


func _physics_process(delta: float) -> void:
	
	if Engine.is_editor_hint(): return
	if states.current_state != "dead": _player_process(Thunder.get_delta(delta))


func _player_process(delta: float) -> void:
	match states.current_state:
		"default": _movement_default(delta)
		"jump": _movement_default(delta)
		"crouch": _movement_default(delta)
	
	velocity = velocity_local.rotated(global_rotation)
	move_and_slide_corrected()
	velocity_local = velocity.rotated(-global_rotation)
	_stomping()
	
	states.update_states(delta)


func _movement_generic(delta: float) -> void:
	# Fall
	velocity_local.y = min(velocity_local.y + config.fall_speed * delta, config.max_fall_speed)
	
	# Decceleration
	if velocity_local.x > 0:
		velocity_local.x = max(velocity_local.x - config.deceleration_speed * delta, 0)
	if velocity_local.x < 0:
		velocity_local.x = min(velocity_local.x + config.deceleration_speed * delta, 0)
	
	# Controls
	if states.current_state != "crouch":
		states.left_or_right = int(Input.get_axis(config.control_left, config.control_right))
	else:
		states.left_or_right = 0
	var walk: int = states.left_or_right
	
	# Acceleration
	
	# Moving left and right
	if walk != 0 && states.current_state != "crouch":
		var speed_x: float = abs(velocity_local.x)
		var mark_x: float = velocity_local.x * sign(walk)
		if speed_x < config.initial_accel_trigger / 2:
			velocity_local.x = config.initial_accel_trigger * walk
		elif mark_x <= -config.initial_accel_trigger:
			velocity_local.x += config.initial_accel_trigger * delta * walk
		elif speed_x < config.max_walk_speed && !Input.is_action_pressed(config.control_run):
			velocity_local.x += config.acceleration_speed * delta * walk
		elif speed_x < config.max_run_speed && Input.is_action_pressed(config.control_run):
			velocity_local.x += config.acceleration_speed * delta * walk


func _movement_default(delta: float) -> void:
	# Hold jump
	if !is_on_floor() && Input.is_action_pressed(config.control_jump) && velocity_local.y < 0:
		states.set_state("jump")
		if abs(velocity_local.x) < 1:
			velocity_local.y -= config.jump_speed_stopped * delta
		else:
			velocity_local.y -= config.jump_speed_moving * delta
	
	# Applying initial acceleration
	if abs(velocity_local.x) < config.initial_accel_trigger && states.left_or_right != 0:
		velocity_local.x = config.initial_acceleration * states.left_or_right
	
	# Direction
	states.dir = abs(velocity_local.x)
	
	if Input.is_action_pressed(config.control_down):
		states.set_state("crouch")
	
	if !Input.is_action_pressed(config.control_down) && states.current_state == "crouch":
		states.set_state("default")
	
	if Input.is_action_just_pressed(config.control_jump) && !is_on_floor() && velocity_local.y > 0:
		states.jump_buffer = true
	
	if Input.is_action_just_released(config.control_jump):
		states.jump_buffer = false
	
	if (Input.is_action_just_pressed(config.control_jump) || states.jump_buffer) && is_on_floor() && states.current_state != "crouch":
		velocity_local.y = -config.jump_velocity
		states.jump_buffer = false
		Audio.play_sound(config.jump_sound, self)
	
	# Generic fall velocity, acceleration and deceleration
	_movement_generic(delta)


func _stomping() -> void:
	if !stomping_cast.shape:
		stomping_cast.shape = shape_big.shape
	stomping_cast.target_position = velocity_local.normalized() * 4
	
	var count: int = stomping_cast.get_collision_count()
	var result: Dictionary
	
	if count <= 0: return
	
	for i in count:
		var casted: Area2D = stomping_cast.get_collider(i) as Area2D
		
		if !casted: continue
		
		var enemy_attacked: Node = casted.get_node_or_null(^"EnemyAttacked")
		
		if !enemy_attacked: continue
		
		result = enemy_attacked.got_stomped(self)
	
	if result.is_empty(): return
	
	if result.result == true:
		if Input.is_action_pressed(config.control_jump):
			velocity_local.y = -result.jumping_max
		else:
			velocity_local.y = -result.jumping_min
	else:
		powerdown()


func _on_state_change(data: PlayerStateData) -> void:
	if !data.player_prefab:
		sprite.visible = false
		sprite_no_img.visible = true
		return
	
	sprite.frames = data.player_prefab
	sprite.visible = true
	sprite_no_img.visible = false
	
	sprite.play()
	
	shape_small.disabled = data.player_power != Data.PLAYER_POWER.SMALL
	shape_big.disabled = data.player_power == Data.PLAYER_POWER.SMALL
	
	powerup_script = null
	if data.player_script:
		powerup_script = ByNodeScript.activate_script(data.player_script, self)


func powerdown() -> void:
	if states.invincible_timer > 0: return
	
	if Thunder._current_player_state.powerdown_state:
		states.appear_timer = config.powerdown_animation_time
		states.invincible_timer = config.powerdown_invincible_time
		Thunder._current_player_state = Thunder._current_player_state.powerdown_state
		Audio.play_sound(config.powerdown_sound, self)
	else:
		kill()


func powerup(state: PlayerStateData) -> void:
	states.appear_timer = config.powerup_animation_time
	states.invincible_timer = config.powerup_animation_time
	Thunder._current_player_state = state


func kill() -> void:
	states.set_state("dead")
