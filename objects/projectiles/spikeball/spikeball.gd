extends Projectile

func _ready() -> void:
	super()
	if speed.x < 0 && sprite_node:
		sprite_node.rotation_speed = -sprite_node.rotation_speed


func _on_trail() -> void:
	if !sprite_node:
		return
	var trail = Effect.trail(self, sprite_node.texture, Vector2.ZERO, sprite_node.flip_h)
	trail.rotation = sprite_node.rotation
	Thunder.reorder_on_top_of(trail, self)


func _on_level_end() -> void:
	if !Thunder.view.is_getting_closer(self, 32):
		if Thunder.view.is_getting_closer(self, 320):
			queue_free()
		return
	Data.values.score += 200
	ScoreText.new(str(200), self)
	queue_free()
