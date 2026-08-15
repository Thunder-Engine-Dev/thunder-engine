extends "res://engine/objects/players/behaviors/player_animation_behavior.gd"

var _swim_frame_progress: float
var _swim_frame: int
var _can_swim_idle: bool
var _hop_walk_finished: bool
var _restart_swim_on_dir_change: bool

#= Connected
func _suit_appeared() -> void:
	if !sprite: return
	sprite.play(&"appear")
	sprite.speed_scale = 1
	
	_setup_tweaks()
	
	await player.get_tree().create_timer(0.02 if _suit_pause_tweak else player.suit.appearing_time_sec, false, true).timeout
	if sprite.animation == &"appear": sprite.play(&"default")


func _swam() -> void:
	if !sprite: return
	_can_swim_idle = false
	if _restart_swim_on_dir_change:
		if sprite.animation in [&"swim", &"swim_up", &"swim_down"]:
			if sprite.frame > 0:
				_restart_swim_anim()
			else:
				sprite.play()
		elif sprite.animation == &"hold_swim" && !sprite.sprite_frames.get_animation_loop(&"hold_swim"):
			if sprite.frame > 0:
				_restart_swim_anim()
			else:
				sprite.play()
		return
	_swim_frame_progress = 0
	if sprite.animation in [&"swim", &"swim_up", &"swim_down"]:
		_swim_frame = 0
		sprite.frame = 0
		sprite.play()
	elif sprite.animation == &"hold_swim" && !sprite.sprite_frames.get_animation_loop(&"hold_swim"):
		_swim_frame = 0
		sprite.frame = 0
		sprite.play()


func _head_bumped() -> void:
	if player.is_underwater: return
	super()


func _sprite_loop() -> void:
	if !sprite: return
	super()
	if sprite.animation == &"walk":
		_hop_walk_finished = true
		_play_anim(_get_animation_prefixed(&"default"))
	elif _restart_swim_on_dir_change && sprite.animation in [&"swim_up", &"swim_down"] && player.left_right == 0 && player.up_down == 0:
		_can_swim_idle = true
		_play_anim(_get_animation_prefixed(&"swim_idle"))

func _sprite_finish() -> void:
	if !sprite: return
	match sprite.animation:
		&"attack", &"idle":
			_play_anim(&"default")
			_animation_process(0)
			_idle_timer = 0.0
		&"walk":
			_hop_walk_finished = true
			_play_anim(_get_animation_prefixed(&"default"))
	if sprite.animation != &"swim_idle":
		_can_swim_idle = true

func _sprite_change() -> void:
	if !sprite: return
	super()


func _setup_tweaks() -> void:
	super()
	_restart_swim_on_dir_change = CharacterManager.get_suit_tweak("frog_restart_swim_on_direction_change", "", player.suit.name) == true


func _restart_swim_anim() -> void:
	var anim := sprite.animation
	sprite.play()
	var start := _get_loop_offset_frame(anim)
	sprite.set_frame_and_progress(start, 0.0)


func _get_loop_offset_frame(anim: StringName) -> int:
	var offset = _loop_offsets.get(anim, -1)
	if offset == null:
		return 0
	var frame := int(offset)
	if frame < 0:
		return 0
	var count := sprite.sprite_frames.get_frame_count(anim)
	if frame >= count:
		return 0
	return frame


#= Main
func _animation_non_warping_process(delta: float) -> void:
	if sprite.animation in [&"appear", &"attack", &"grab", &"kick"]: return
	_loop_offsets.walk = 0
	# Climbing
	if player.is_climbing:
		return _animation_climbing_process(delta)
	if player.is_sliding:
		return _animation_sliding_process(delta)
	# Non-climbing
	player.skid.emitting = false
	if player.is_underwater && !player.completed:
		return _animation_swimming_process(delta)
	if player.is_on_floor() || player.coyote_time > 0.0:
		sprite.sprite_frames.set_animation_loop(&"walk", false)
		_loop_offsets.walk = sprite.sprite_frames.get_frame_count(&"walk") - 1
		_animation_floor_process(delta)
	else:
		_animation_jumping_process(delta)

func _animation_floor_process(delta: float) -> void:
	var keep_hop_walk := !player.is_holding && sprite.animation == &"walk" && sprite.is_playing()
	if !keep_hop_walk && _wants_frog_look_up():
		_p_run_enabled = false
		_play_anim(_get_animation_prefixed(&"look_up"))
	elif !(is_zero_approx(player.speed.x)) && !player.has_stuck && !(player.has_stuck_animation && player.left_right == 0):
		if player.is_holding:
			_play_anim(&"hold_walk" if !player.is_skidding else &"skid")
			_p_run_enabled = false
			sprite.speed_scale = (
				clampf(abs(player.speed.x) * 0.008 * config.animation_walking_speed,
				config.animation_min_walking_speed,
				config.animation_max_walking_speed)
			)
		elif player._physics_behavior.jump_delay >= 0:
			if player._physics_behavior.jump_delay < 0.08:
				_hop_walk_finished = false
			if _hop_walk_finished:
				_play_anim(&"default")
			else:
				_play_anim(&"walk" if !player.is_skidding else &"skid")
			_p_run_enabled = false
			sprite.speed_scale = 1
	else:
		_p_run_enabled = false
		if !keep_hop_walk:
			_idle_timer += delta
			if _idle_tweak && !player.is_holding && _idle_timer > _idle_activate_after_sec:
				_play_anim(&"idle")
			else:
				_play_anim(_get_animation_prefixed(&"default"))
	
	#if player._physics_behavior.jump_delay < 0 && !player.completed:
	#	sprite.set_frame_and_progress(0, 0.8)
	player.skid.emitting = false
	if player.completed:
		if sprite.animation in [&"swim", &"swim_up", &"swim_down", &"swim_idle", &"hold_swim"]:
			sprite.animation = _get_animation_prefixed(&"walk")
		if sprite.animation == _get_animation_prefixed(&"walk"):
			sprite.sprite_frames.set_animation_loop(&"walk", true)
			sprite.speed_scale = 2.4
			sprite.play()


func _wants_frog_look_up() -> bool:
	if player.up_down != -1 || !_look_up_tweak || player.slow_walking:
		return false
	if player._physics_behavior.hop_pausing:
		return false
	if abs(player.speed.x) > 1:
		return false
	if player.left_right == 0:
		return true
	if player.is_on_slope():
		return false
	return player.test_move(player.transform, Vector2(player.left_right, 0))


func _animation_swimming_process(delta: float) -> void:
	_p_run_enabled = false
	if sprite.animation in [&"swim", &"swim_up", &"swim_down"]:
		_swim_frame = sprite.get_frame()
		_swim_frame_progress = sprite.get_frame_progress()

	if player.is_holding:
		if sprite.animation == &"hold_swim":
			return
		_play_anim(&"hold_swim")
		return

	if _restart_swim_on_dir_change:
		if player.up_down == 0 && player.left_right == 0 && sprite.animation in [&"swim_up", &"swim_down"] && sprite.is_playing():
			return
		if _can_swim_idle && player.left_right == 0 && player.up_down == 0:
			if sprite.animation == &"swim_idle": return
			_play_anim(_get_animation_prefixed(&"swim_idle"))
			return
		if player.up_down > 0 && player.left_right == 0:
			if sprite.animation == &"swim_down": return
			_play_anim(&"swim_down")
		elif player.up_down < 0 && player.left_right == 0:
			if sprite.animation == &"swim_up": return
			_play_anim(&"swim_up")
		else:
			if sprite.animation == &"swim": return
			_play_anim(&"swim")
		return

	if _can_swim_idle && player.left_right == 0 && player.up_down == 0:
		if sprite.animation == &"swim_idle": return
		_play_anim(_get_animation_prefixed(&"swim_idle"))
		return

	if player.up_down > 0 && player.left_right == 0:
		if sprite.animation == &"swim_down": return
		_play_anim(&"swim_down")
		sprite.set_frame_and_progress(_swim_frame, _swim_frame_progress)
	elif player.up_down < 0 && player.left_right == 0:
		if sprite.animation == &"swim_up": return
		_play_anim(&"swim_up")
		sprite.set_frame_and_progress(_swim_frame, _swim_frame_progress)
	else:
		if sprite.animation == &"swim": return
		_play_anim(_get_animation_prefixed(&"swim"))
		sprite.set_frame_and_progress(_swim_frame, _swim_frame_progress)


func _animation_warping_process() -> void:
	player.skid.emitting = false
	_idle_timer = 0.0
	match player.warp_dir:
		Player.WarpDir.DOWN:
			_play_anim(&"warp" if _warp_tweak else _get_animation_prefixed(&"default"))
		Player.WarpDir.UP:
			_play_anim(&"warp" if _warp_tweak else _get_animation_prefixed(&"jump"))
		Player.WarpDir.LEFT, Player.WarpDir.RIGHT:
			player.direction = -1 if player.warp_dir == Player.WarpDir.LEFT else 1
			sprite.sprite_frames.set_animation_loop(&"walk", true)
			_loop_offsets.walk = 0
			_play_anim(_get_animation_prefixed(&"walk"))
			player._physics_behavior.jump_delay = -0.02
			sprite.speed_scale = 2
			sprite.play()
