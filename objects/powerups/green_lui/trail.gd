extends Sprite2D

func _ready():
	var player: Player = Thunder._current_player
	texture = player.sprite.sprite_frames.get_frame_texture(player.sprite.animation, player.sprite.frame)
	offset = player.sprite.offset
	flip_h = player.sprite.flip_h
	flip_v = player.sprite.flip_v

func _physics_process(delta: float) -> void:
	modulate.a -= 0.05 * Thunder.get_delta(delta)
	if modulate.a <= 0.0:
		queue_free()
