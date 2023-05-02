extends ByNodeScript

var player: Player
var sprite: AnimatedSprite2D


func _ready() -> void:
	player = node as Player
	sprite = node.sprite as AnimatedSprite2D
	
	# Connect animation signals for the current powerup
	player.suit_appeared.connect(_suit_appeared)
	player.swam.connect(_swam)
	player.shot.connect(_shot)
	player.invinciblized.connect(_invincible)
	
	sprite.animation_looped.connect(_sprite_loop)
	sprite.animation_finished.connect(_sprite_finish)


func _physics_process(delta: float) -> void:
	if player.get_tree().paused: return
	delta = player.get_physics_process_delta_time()
	_animation_process(delta)


#= Connected
func _suit_appeared() -> void:
	if !sprite: return
	sprite.play(&"appear")
	await player.get_tree().create_timer(1, false, true).timeout
	if sprite.animation == &"appear": sprite.play(&"default")


func _swam() -> void:
	if !sprite: return
	if sprite.animation == &"swim" && sprite.frame > 2: sprite.frame = 0


func _shot() -> void:
	if !sprite: return
	sprite.play(&"attack")


func _invincible(duration: float) -> void:
	if !sprite: return
	sprite.modulate.a = 1
	Effect.flash(sprite, duration)


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
	
	if player.direction != 0:
		sprite.flip_h = (player.direction < 0)
	sprite.speed_scale = 1
	# Non-warping
	if player.warp == Player.Warp.NONE:
		if sprite.animation in [&"appear", &"attack"]: return
		if player.is_on_floor():
			if player.speed.x != 0:
				sprite.play(&"walk")
				sprite.speed_scale = clampf(abs(player.speed.x) * delta * 1.5, 1, 5)
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
			Player.WarpDir.UP:
				sprite.play(&"jump")
			Player.WarpDir.DOWN:
				sprite.play(&"crouch")
			Player.WarpDir.LEFT, Player.WarpDir.RIGHT:
				player.direction = -1 if player.warp_dir == Player.WarpDir.LEFT else 1
				sprite.play(&"walk")
				sprite.speed_scale = 2
