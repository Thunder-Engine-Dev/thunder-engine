extends PlayerPhysicsModifier

@export var sliding_effect: PackedScene = preload("res://engine/objects/effects/slide/slide_effect.tscn")
@export var sound_sliding: AudioStream = preload("res://engine/objects/platform/sound/sliding.mp3")

var sliding_sound_interval: SceneTreeTimer
var sliding_effect_emitter: GPUParticles2D

func _logic() -> void:
	if player.left_right == -player.direction && abs(player.speed.x) > 0:
		if !is_instance_valid(sliding_effect_emitter) && sliding_effect:
			sliding_effect_emitter = sliding_effect.instantiate()
			sliding_effect_emitter.z_index = 2
			add_sibling.call_deferred(sliding_effect_emitter)
			sliding_effect_emitter.reset_physics_interpolation()
		_slide()
	else: _end_logic(false)

func _end_logic(remove: bool) -> void:
	if !is_instance_valid(sliding_effect_emitter): return
	#if is_instance_valid(player) && !remove:
	#	player.suit.physics_config.animation_min_walking_speed = 1
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

func _deinitialise() -> void:
	sliding_effect_emitter = null


func _slide() -> void:
	if !is_instance_valid(player): return
	player.suit.physics_config.animation_min_walking_speed = 5
	player.suit.physics_config.animation_max_walking_speed = 5
	if sliding_sound_interval: return
	if is_instance_valid(sliding_effect_emitter):
		sliding_effect_emitter.global_position = player.global_transform.translated_local(Vector2.DOWN * 16).get_origin()
		sliding_effect_emitter.reset_physics_interpolation()
	sliding_sound_interval = get_tree().create_timer(0.15, false)
	await sliding_sound_interval.timeout
	sliding_sound_interval = null
	if player:
		var _sfx = CharacterManager.get_sound_replace(sound_sliding, sound_sliding, "ice_slide", true)
		Audio.play_sound(_sfx, player)
