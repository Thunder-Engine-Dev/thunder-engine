extends Projectile

@onready var vision: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	super()
	if speed.x < 0 && sprite_node:
		sprite_node.rotation_speed = -sprite_node.rotation_speed
	
	if sprite_node:
		var tw = create_tween()
		tw.tween_property(sprite_node, "scale", Vector2.ONE, 0.05)
	
	await get_tree().physics_frame
	if belongs_to == Data.PROJECTILE_BELONGS.ENEMY:
		# Delete projectile if shot by enemy off-screen
		if !vision.is_on_screen():
			queue_free()


func _on_level_end() -> void:
	if !Thunder.view.is_getting_closer(self, 32):
		if Thunder.view.is_getting_closer(self, 320):
			queue_free()
		return
	Data.values.score += 200
	ScoreText.new(str(200), self)
	queue_free()
