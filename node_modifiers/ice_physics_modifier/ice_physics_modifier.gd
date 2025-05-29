extends NodeModifier

@export var sliding_effect: PackedScene = preload("res://engine/objects/effects/slide/slide_effect.tscn")
@export var sound_sliding: AudioStream = preload("res://engine/objects/platform/sound/sliding.mp3")

var is_slippery: bool
var old_config: PlayerConfig
var player: Player = null

var sliding_sound_interval: SceneTreeTimer
var sliding_effect_emitter: GPUParticles2D


func _ready():
	Thunder._current_player.suit_changed.connect((func(a = null):
		_remove_slippery(Thunder._current_player)
	), CONNECT_DEFERRED + CONNECT_REFERENCE_COUNTED + CONNECT_ONE_SHOT)


func _physics_process(delta):
	var prev_state: Player = player
	player = null
	
	if prev_state && !is_slippery:
		if !is_instance_valid(prev_state):
			sliding_effect_emitter = null
			return
		_add_slippery(prev_state)
	
	var kc: = KinematicCollision2D.new()
	target_node.test_move(target_node.global_transform, Vector2.UP.rotated(target_node.global_rotation), kc)
	if kc:
		var collider: = kc.get_collider()
		if collider is Player:
			player = collider
			if player.left_right == -player.direction && abs(player.speed.x) > 0:
				if !is_instance_valid(sliding_effect_emitter) && sliding_effect:
					sliding_effect_emitter = sliding_effect.instantiate()
					sliding_effect_emitter.z_index = 2
					add_sibling.call_deferred(sliding_effect_emitter)
				_slide()
			else: _end_slide(false)
	
	if !player && prev_state && is_slippery:
		_remove_slippery(prev_state)
		_end_slide(true)


func _add_slippery(_player) -> void:
	if !_player: return
	old_config = _player.suit.physics_config
	_player.suit.physics_config = old_config.duplicate(true)
	
	_player.suit.physics_config.walk_acceleration = old_config.walk_acceleration / 2
	_player.suit.physics_config.walk_initial_speed = old_config.walk_initial_speed / 2
	_player.suit.physics_config.walk_deceleration = old_config.walk_deceleration / 4
	_player.suit.physics_config.walk_turning_acce = old_config.walk_turning_acce / 6
	is_slippery = true


func _remove_slippery(_player) -> void:
	if !_player: _player = Thunder._current_player
	if !is_instance_valid(_player): return
	if !old_config: return
	
	_player.suit.physics_config = old_config
	_player.suit.physics_config.walk_acceleration = old_config.walk_acceleration
	_player.suit.physics_config.walk_deceleration = old_config.walk_deceleration
	_player.suit.physics_config.walk_turning_acce = old_config.walk_turning_acce
	_player.suit.physics_config.animation_min_walking_speed = 1#old_config.animation_min_walking_speed
	_player.suit.physics_config.animation_max_walking_speed = 5#old_config.animation_max_walking_speed
	is_slippery = false


func _slide() -> void:
	if !is_instance_valid(player): return
	player.suit.physics_config.animation_min_walking_speed = 6
	player.suit.physics_config.animation_max_walking_speed = 6
	if sliding_sound_interval: return
	if is_instance_valid(sliding_effect_emitter):
		sliding_effect_emitter.global_position = player.global_transform.translated_local(Vector2.DOWN * 16).get_origin()
	sliding_sound_interval = get_tree().create_timer(0.15, false)
	await sliding_sound_interval.timeout
	sliding_sound_interval = null
	if player: Audio.play_sound(sound_sliding, player)


func _end_slide(end: bool) -> void:
	if !is_instance_valid(sliding_effect_emitter): return
	if is_instance_valid(player) && !end:
		player.suit.physics_config.animation_min_walking_speed = 1
	var dupeff := sliding_effect_emitter.duplicate() as GPUParticles2D
	get_parent().add_sibling.call_deferred(dupeff)
	dupeff.global_transform = sliding_effect_emitter.global_transform
	dupeff.one_shot = true
	dupeff.restart()
	dupeff.reset_physics_interpolation()
	dupeff.finished.connect(
		func() -> void:
			dupeff.queue_free()
	)
	sliding_effect_emitter.queue_free()
	sliding_effect_emitter = null
