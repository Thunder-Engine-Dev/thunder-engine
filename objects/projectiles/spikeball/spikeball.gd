extends Projectile


func _on_trail() -> void:
	if !sprite_node:
		return
	Effect.trail(self, sprite_node.texture, Vector2.ZERO, sprite_node.flip_h).rotation = sprite_node.rotation


func _on_level_end() -> void:
	if !Thunder.view.is_getting_closer(self, 32):
		if Thunder.view.is_getting_closer(self, 320):
			queue_free()
		return
	Data.values.score += 200
	ScoreText.new(str(200), self)
	queue_free()
