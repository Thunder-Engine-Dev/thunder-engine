extends Projectile

@onready var vision: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@export var remove_offscreen_after: float = 4.0

func _ready() -> void:
	offscreen_handler(remove_offscreen_after)
	super()
	if speed.x < 0 && sprite_node:
		sprite_node.rotation_speed = -sprite_node.rotation_speed
	
	if sprite_node:
		var tw = create_tween()
		tw.tween_property(sprite_node, "scale", Vector2.ONE, 0.05)


func _on_level_end() -> void:
	if !Thunder.view.is_getting_closer(self, 32):
		if Thunder.view.is_getting_closer(self, 320):
			queue_free()
		return
	Data.add_score(200)
	ScoreText.new(str(200), self)
	queue_free()
