extends ByNodeScript

var player: Player
var sprite: AnimatedSprite2D
var config: PlayerConfig

var _climb_progress: float
var _suit_pause_tweak: bool

func _ready() -> void:
	player = node as Player
	sprite = node.sprite as AnimatedSprite2D
	
	_suit_pause_tweak = SettingsManager.get_tweak("pause_on_suit_change", false)
	
	# Connect animation signals for the current powerup
	player.suit_appeared.connect(_suit_appeared)
	player.swam.connect(_swam)
	player.shot.connect(_shot)
	player.invinciblized.connect(_invincible)
	
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
	await player.get_tree().create_timer(0.02 if _suit_pause_tweak else 1, false, true).timeout
	if sprite.animation == &"appear": sprite.play(&"default")


func _swam() -> void:
	if !sprite: return
	if sprite.animation == &"swim" && sprite.frame > 2: sprite.frame = 0


func _shot() -> void:
	if !sprite: return
	if sprite.animation == &"swim":
		sprite.frame = 3
		return
	sprite.play(&"attack")


func _invincible(duration: float) -> void:
	if !sprite: return
	sprite.modulate.a = 1
	if !player.is_starman():
		Effect.flash(sprite, duration, 0.06, Tween.TWEEN_PAUSE_STOP)


func _sprite_loop() -> void:
	if !sprite: return
	match sprite.animation:
		&"swim": sprite.frame = sprite.sprite_frames.get_frame_count(sprite.animation) - 2


func _sprite_finish() -> void:
	if !sprite: return
	if sprite.animation == &"attack": sprite.play(&"default")


#= Main
func _animation_process(delta: float) -> void:
	if !sprite: return
	
	if player.direction != 0 && !player.is_climbing:
		sprite.flip_h = (player.direction < 0)
	sprite.speed_scale = 1
	# Non-warping
	if player.warp == Player.Warp.NONE:
		if sprite.animation in [&"appear", &"attack"]: return
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
			return
		# Non-climbing
		if player.is_on_floor():
			if !(is_zero_approx(player.speed.x)):
				sprite.play(&"walk")
				sprite.speed_scale = (
					clampf(abs(player.speed.x) * 0.008 * config.animation_walking_speed,
					config.animation_min_walking_speed,
					config.animation_max_walking_speed)
				)
			else:
				sprite.play(&"default")
			if player.is_crouching:
				sprite.play(&"crouch")
		elif player.is_underwater:
			sprite.play(&"swim")
		else:
			sprite.play(&"jump")
	# Warping
	else:
		match player.warp_dir:
			Player.WarpDir.UP, Player.WarpDir.DOWN:
				sprite.play(&"warp")
			Player.WarpDir.LEFT, Player.WarpDir.RIGHT:
				player.direction = -1 if player.warp_dir == Player.WarpDir.LEFT else 1
				sprite.play(&"walk")
				sprite.speed_scale = 2
