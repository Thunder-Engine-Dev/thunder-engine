extends Projectile

func _ready() -> void:
	super()
	offscreen_handler()


func _physics_process(delta: float) -> void:
	super(delta)
	if !sprite_node: return
	sprite_node.rotation_degrees += 8 * (-1 if speed.x < 0 else 1) * Thunder.get_delta(delta)


func _on_level_end() -> void:
	if !Thunder.view.is_getting_closer(self, 32):
		if Thunder.view.is_getting_closer(self, 320):
			queue_free()
		return
	Data.values.score += 200
	ScoreText.new(str(200), self)
	queue_free()
