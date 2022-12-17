@tool
extends CorrectedCharacterBody2D
class_name Player

@export var config: PlayerConfiguration = PlayerConfiguration.new()
var states: PlayerStateManager = PlayerStateManager.new()

var sprites: Node2D

func _ready() -> void:
	if Engine.is_editor_hint(): return
	Thunder._current_player = self
	
	sprites = $Sprites
	
	sprites.teleport()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if states.current_state != "dead": _player_process(Thunder.get_delta(delta))


func _player_process(delta: float) -> void:
	states.update_states()
	
	match states.current_state:
		"default": _movement_default(delta)
	
	move_and_slide_corrected()


func _movement_generic(delta: float) -> void:
	# Fall
	velocity.y = min(velocity.y + config.fall_speed * delta, config.max_fall_speed)
	
	# Deceleration
	if velocity.x > 0:
		velocity.x = max(velocity.x - config.deceleration_speed * delta, 0)
	if velocity.x < 0:
		velocity.x = min(velocity.x + config.deceleration_speed * delta, 0)
	
	# Acceleration
	
	# Moving right
	if Input.is_action_pressed('m_right'):
		if abs(velocity.x) < config.initial_accel_trigger / 2:
			velocity.x = config.initial_accel_trigger
		elif velocity.x <= -config.initial_accel_trigger:
			velocity.x += config.initial_accel_trigger * delta
		elif abs(velocity.x) < config.max_walk_speed && !Input.is_action_pressed('m_run'):
			velocity.x += config.acceleration_speed * delta
		elif abs(velocity.x) < config.max_run_speed && Input.is_action_pressed('m_run'):
			velocity.x += config.acceleration_speed * delta
	
	# Moving left
	if Input.is_action_pressed('m_left'):
		if abs(velocity.x) < config.initial_accel_trigger / 2:
			velocity.x = -config.initial_accel_trigger
		elif velocity.x >= config.initial_accel_trigger:
			velocity.x -= config.initial_accel_trigger * delta
		elif abs(velocity.x) < config.max_walk_speed && !Input.is_action_pressed('m_run'):
			velocity.x -= config.acceleration_speed * delta
		elif abs(velocity.x) < config.max_run_speed && Input.is_action_pressed('m_run'):
			velocity.x -= config.acceleration_speed * delta
	
	if Input.is_action_just_pressed("m_jump") && !is_on_floor() && velocity.y > 0:
		states.jump_buffer = true
	
	if Input.is_action_just_released("m_jump"):
		states.jump_buffer = false
	
	if (Input.is_action_just_pressed("m_jump") || states.jump_buffer) && is_on_floor():
		velocity.y = -700
		states.jump_buffer = false


func _movement_default(delta: float) -> void:
	# Hold jump
	if !is_on_floor() && Input.is_action_pressed("m_jump") && velocity.y < 0:
		if abs(velocity.x) < 1:
			velocity.y -= config.jump_speed_stopped * delta
		else:
			velocity.y -= config.jump_speed_moving * delta
	
	# Applying initial acceleration
	if abs(velocity.x) < config.initial_accel_trigger && Input.get_axis("m_left", "m_right"):
		velocity.x = config.initial_acceleration * Input.get_axis("m_left", "m_right")
	
	# Generic fall velocity, acceleration and deceleration
	_movement_generic(delta)
