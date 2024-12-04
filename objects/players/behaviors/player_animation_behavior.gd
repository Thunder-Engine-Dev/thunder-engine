extends ByNodeScript

const BUBBLE = preload("res://engine/objects/effects/bubble/bubble.tscn")

var player: Player
var sprite: AnimatedSprite2D
var config: PlayerConfig

var _climb_progress: float
var _suit_pause_tweak: bool
var _attack_air_tweak: bool

func _ready() -> void:
	player = node as Player
	sprite = node.sprite as AnimatedSprite2D
	
	_suit_pause_tweak = SettingsManager.get_tweak("pause_on_suit_change", false)
	_attack_air_tweak = SettingsManager.get_tweak("air_attack_animation", false)
	
	# Connect animation signals for the current powerup
	player.suit_appeared.connect(_suit_appeared)
	player.swam.connect(_swam)
	player.shot.connect(_shot)
	player.threw.connect(_threw)
	player.grabbed.connect(_grabbed)
	player.invinciblized.connect(_invincible)
	
	player.bubbler.timeout.connect(_bubble_spawn)
	
	sprite.animation_looped.connect(_sprite_loop)
	sprite.animation_finished.connect(_sprite_finish)


func _physics_process(delta: float) -> void:
	if player.get_tree().paused: return
	config = node.suit.physics_config
	
	delta = player.get_physics_process_delta_time()
	_animation_process(delta)


#= Connected
func _suit_appeared() -> void:
	if !sprite: return
	sprite.play(&"appear")
	sprite.speed_scale = 1
	await player.get_tree().create_timer(0.02 if _suit_pause_tweak else 1.0, false, true).timeout
	if sprite.animation == &"appear": sprite.play(&"default")


func _swam() -> void:
	if !sprite: return
	if sprite.animation == &"swim" && sprite.frame > 2: sprite.frame = 0


func _shot() -> void:
	if !sprite: return
	if sprite.animation == &"swim":
		sprite.frame = 3
		return
	if player.is_climbing: return
	if sprite.animation in [&"attack", &"attack_air"]:
		sprite.frame = 0
	
	if _attack_air_tweak:
		sprite.play(&"attack" if player.is_on_floor() else &"attack_air")
	elif player.is_on_floor():
		sprite.play(&"attack")


func _invincible(duration: float) -> void:
	if !sprite: return
	sprite.modulate.a = 1
	if !player.is_starman():
		player.flasher = Effect.flash(sprite, duration, 0.06, Tween.TWEEN_PAUSE_STOP)


func _bubble_spawn() -> void:
	if randi_range(0, 9) != 0 || player.warp != player.Warp.NONE:
		return
	var bubble = BUBBLE.instantiate()
	bubble.transform = player.global_transform
	var _of: Vector2 = node.suit.animation_underwater_bubble_offset
	bubble.position += Vector2(_of.x * player.direction, _of.y)
	Scenes.current_scene.add_child(bubble)


func _sprite_loop() -> void:
	if !sprite: return
	match sprite.animation:
		&"swim": sprite.frame = sprite.sprite_frames.get_frame_count(sprite.animation) - 2


func _sprite_finish() -> void:
	if !sprite: return
	if sprite.animation == &"attack": sprite.play(&"default")
	if sprite.animation == &"attack_air": sprite.play(&"jump" if player.speed.y < 0 else &"fall")


var _skid_sound_timer: bool
func _skid_sound_loop() -> void:
	if _skid_sound_timer: return
	_skid_sound_timer = true
	Audio.play_sound(player.skid_sound, player)
	await player.get_tree().create_timer(0.10, false, false, true).timeout
	_skid_sound_timer = false


func _grabbed(side_grabbed: bool) -> void:
	if !sprite || side_grabbed: return
	sprite.play(&"grab")
	_handle_grabbed_finished()


func _threw() -> void:
	if !sprite: return
	if sprite.animation != &"appear":
		sprite.play(&"kick")
		_handle_grabbed_finished()


func _handle_grabbed_finished() -> void:
	await sprite.animation_finished
	sprite.play(&"hold_default")


#= Main
func _animation_process(delta: float) -> void:
	if !sprite: return
	
	if player.direction != 0 && !player.is_climbing:
		sprite.flip_h = (player.direction < 0)
	sprite.speed_scale = 1
	# Non-warping
	if player.warp == Player.Warp.NONE:
		player.skid.emitting = false
		if sprite.animation in [&"appear", &"attack", &"grab", &"kick"]: return
		# Climbing
		if player.is_climbing:
			sprite.play(&"climb")
			if player.speed != Vector2.ZERO:
				_climb_progress += abs(player.speed.length() * delta)
				if _climb_progress > 20:
					_climb_progress = 0
					sprite.flip_h = !sprite.flip_h
			return
		if player.is_sliding:
			sprite.play(&"slide")
			sprite.speed_scale = clampf(abs(player.speed.x) * 0.01 * 1.5, 1, 5)
			player.skid.emitting = player.is_on_floor()
			return
		# Non-climbing
		player.skid.emitting = player.is_skidding
		if player.is_skidding:
			_skid_sound_loop()
		if player.is_on_floor():
			if !(is_zero_approx(player.speed.x)):
				sprite.play(
					StringName(_get_animation_prefixed(&"walk")) if !player.is_skidding else &"skid"
				)
				sprite.speed_scale = (
					clampf(abs(player.speed.x) * 0.008 * config.animation_walking_speed,
					config.animation_min_walking_speed,
					config.animation_max_walking_speed)
				)
			else:
				sprite.play(_get_animation_prefixed(&"default"))
			if player.is_crouching:
				sprite.play(_get_animation_prefixed(&"crouch"))
				player.skid.emitting = player._skid_tweak && !(is_zero_approx(player.speed.x))
		elif player.is_underwater:
			sprite.play(&"swim")
		else:
			if sprite.animation == &"attack_air": return
			if player.speed.y < 0:
				sprite.play(_get_animation_prefixed(&"jump"))
			else:
				sprite.play(_get_animation_prefixed(&"fall"))
	# Warping
	else:
		match player.warp_dir:
			Player.WarpDir.UP, Player.WarpDir.DOWN:
				sprite.play(&"warp")
			Player.WarpDir.LEFT, Player.WarpDir.RIGHT:
				player.direction = -1 if player.warp_dir == Player.WarpDir.LEFT else 1
				sprite.play(_get_animation_prefixed(&"walk"))
				sprite.speed_scale = 2

func _get_animation_prefixed(anim_name: String) -> String:
	if player.is_holding:
		return "hold_%s" % anim_name
	return anim_name
