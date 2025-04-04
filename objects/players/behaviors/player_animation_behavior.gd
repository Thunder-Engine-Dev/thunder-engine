extends ByNodeScript

const BUBBLE = preload("res://engine/objects/effects/bubble/bubble.tscn")
const BUMP = preload("res://engine/objects/bumping_blocks/_sounds/bump.wav")

var player: Player
var sprite: AnimatedSprite2D
var config: PlayerConfig

var _suit_pause_tweak: bool
var _attack_air_tweak: bool
var _idle_tweak: bool
var _idle_activate_after_sec: float
var _look_up_tweak: bool
var _separate_run_tweak: bool
var _stomp_anim_tweak: bool
var _warp_tweak: bool
var _head_bump_sound: bool
var _skid_sound_loop_delay: float
var _look_up_sound: AudioStream
var _loop_offsets: Dictionary = {}

var _climb_progress: float
var _p_run_enabled: bool
var _stomp_enabled: bool
var _idle_timer: float
var _previous_animation: String

func _ready() -> void:
	player = node as Player
	sprite = node.sprite as AnimatedSprite2D
	
	_suit_pause_tweak = SettingsManager.get_tweak("pause_on_suit_change", false)
	_setup_tweaks()
	
	# Connect animation signals for the current powerup
	player.suit_appeared.connect(_suit_appeared)
	player.swam.connect(_swam)
	player.shot.connect(_shot)
	player.threw.connect(_threw)
	player.grabbed.connect(_grabbed)
	player.invinciblized.connect(_invincible)
	player.head_bumped.connect(_head_bumped)
	
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
	
	_setup_tweaks()
	
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
	else:
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
	for anim in _loop_offsets.keys():
		if _loop_offsets[anim] < 0: continue
		if sprite.animation == anim:
			sprite.frame = _loop_offsets[anim]
		#&"swim": sprite.frame = sprite.sprite_frames.get_frame_count(sprite.animation) - 2


func _sprite_finish() -> void:
	if !sprite: return
	match sprite.animation:
		&"attack", &"idle":
			_play_anim(&"default")
			_idle_timer = 0.0
		&"attack_air":
			_play_anim(&"jump" if player.speed.y < 0 else &"fall")


var _skid_sound_timer: bool
func _skid_sound_loop() -> void:
	if _skid_sound_timer: return
	_skid_sound_timer = true
	Audio.play_sound(config.sound_skid, player)
	var _clamped_loop: float = clampf(_skid_sound_loop_delay, 0.05, 2.0)
	await player.get_tree().create_timer(_clamped_loop, false, false, true).timeout
	_skid_sound_timer = false


func _head_bumped() -> void:
	if !_head_bump_sound: return
	
	Audio.play_sound(CharacterManager.get_sound_replace(BUMP, BUMP, "block_bump", false), player)


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
	sprite.animation_finished.connect(func():
		sprite.play(&"hold_default")
	, CONNECT_ONE_SHOT)
	


func _setup_tweaks() -> void:
	_attack_air_tweak = CharacterManager.get_suit_tweak("attack_air_animation", "", player.suit.name)
	_look_up_tweak = CharacterManager.get_suit_tweak("look_up_animation", "", player.suit.name)
	_idle_tweak = CharacterManager.get_suit_tweak("idle_animation", "", player.suit.name)
	_idle_activate_after_sec = CharacterManager.get_suit_tweak("idle_activate_after_sec", "", player.suit.name)
	_separate_run_tweak = CharacterManager.get_suit_tweak("separate_run_animation", "", player.suit.name)
	_stomp_anim_tweak = false #CharacterManager.get_suit_tweak("stomp_animation", "", player.suit.name)
	_warp_tweak = CharacterManager.get_suit_tweak("warp_animation", "", player.suit.name)
	_skid_sound_loop_delay = CharacterManager.get_suit_tweak("skid_sound_loop_delay", "", player.suit.name)
	_head_bump_sound = CharacterManager.get_suit_tweak("head_bump_sound", "", player.suit.name)
	var _up_sfx: Array = CharacterManager.get_suit_sound("look_up", "", player.suit.name)
	if _up_sfx:
		_look_up_sound = _up_sfx.front()
	var _off = CharacterManager.get_suit_tweak("loop_frame_offsets", "", player.suit.name)
	if _off is Dictionary:
		_loop_offsets = _off


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
			_play_anim(&"climb")
			if player.speed != Vector2.ZERO:
				_climb_progress += abs(player.speed.length() * delta)
				if _climb_progress > 20:
					_climb_progress = 0
					sprite.flip_h = !sprite.flip_h
			return
		if player.is_sliding:
			_play_anim(&"slide")
			sprite.speed_scale = clampf(abs(player.speed.x) * 0.01 * 1.5, 1, 5)
			player.skid.emitting = player.is_on_floor()
			return
		# Non-climbing
		player.skid.emitting = player.is_skidding
		if player.is_skidding:
			_skid_sound_loop()
		if player.is_on_floor() || player.coyote_time > 0.0:
			_stomp_enabled = false
			if !(is_zero_approx(player.speed.x)):
				if _separate_run_tweak && abs(player.speed.x) + 25 >= config.walk_max_running_speed && !player.is_holding:
					_play_anim(&"p_run" if !player.is_skidding else &"skid")
					_p_run_enabled = true
				else:
					_play_anim(
						StringName(_get_animation_prefixed(&"walk")) if !player.is_skidding else &"skid"
					)
					_p_run_enabled = false
				sprite.speed_scale = (
					clampf(abs(player.speed.x) * 0.008 * config.animation_walking_speed,
					config.animation_min_walking_speed,
					config.animation_max_walking_speed)
				)
			else:
				_p_run_enabled = false
				if player.up_down == -1 && !player.is_holding && _look_up_tweak:
					if !sprite.animation in [&"look_up", &"hold_look_up"]:
						Audio.play_sound(_look_up_sound, player, false)
					_play_anim(_get_animation_prefixed(&"look_up"))
				else:
					_idle_timer += delta
					if _idle_tweak && !player.is_holding && _idle_timer > _idle_activate_after_sec:
						_play_anim(&"idle")
					else:
						_play_anim(_get_animation_prefixed(&"default"))
			if player.is_crouching || player.crouch_forced:
				_p_run_enabled = false
				_play_anim(_get_animation_prefixed(&"crouch"))
				player.skid.emitting = player._skid_tweak && !(is_zero_approx(player.speed.x))
		elif player.is_underwater:
			_p_run_enabled = false
			_play_anim(_get_animation_prefixed(&"swim"))
		else:
			if sprite.animation == &"attack_air": return
			if _stomp_enabled && !_p_run_enabled:
				_play_anim(&"stomp")
			elif player.crouch_forced:
				_play_anim(_get_animation_prefixed(&"crouch"))
			else:
				if player.speed.y < 0:
					_play_anim(_get_animation_prefixed(&"jump") if !_p_run_enabled else &"p_jump")
				else:
					_play_anim(_get_animation_prefixed(&"fall") if !_p_run_enabled else &"p_fall")
	# Warping
	else:
		player.skid.emitting = false
		_idle_timer = 0.0
		match player.warp_dir:
			Player.WarpDir.DOWN:
				_play_anim(
					&"warp" if _warp_tweak else (
						_get_animation_prefixed(
							&"default" if Thunder.is_player_power(Data.PLAYER_POWER.SMALL) else &"crouch"
						)
					)
				)
			Player.WarpDir.UP:
				_play_anim(&"warp" if _warp_tweak else _get_animation_prefixed(&"jump"))
			Player.WarpDir.LEFT, Player.WarpDir.RIGHT:
				player.direction = -1 if player.warp_dir == Player.WarpDir.LEFT else 1
				_play_anim(_get_animation_prefixed(&"walk"))
				sprite.speed_scale = 2

func _get_animation_prefixed(anim_name: StringName) -> StringName:
	if player.is_holding:
		return &"hold_%s" % anim_name
	return anim_name

func _play_anim(animation: StringName) -> void:
	if animation != &"default" && animation != &"idle":
		_idle_timer = 0.0
	if sprite.animation != animation || _previous_animation == "":
		if sprite.sprite_frames.has_animation(animation):
			sprite.play(animation)
		_previous_animation = animation
	else:
		sprite.animation = animation
