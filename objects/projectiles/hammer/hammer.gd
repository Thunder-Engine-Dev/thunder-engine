extends Projectile

@export var remove_offscreen_after: float = 2.5
@export var remove_top_offscreen: bool = false

func _ready() -> void:
	super()
	if !remove_top_offscreen:
		vision_node.rect.size.y = 618
	offscreen_handler(remove_offscreen_after)


func _physics_process(delta: float) -> void:
	super(delta)
	if !sprite_node: return
	sprite_node.rotation_degrees += 8 * (-1 if speed.x < 0 else 1) * Thunder.get_delta(delta)


func _on_level_end() -> void:
	if !Thunder.view.is_getting_closer(self, 32):
		if Thunder.view.is_getting_closer(self, 320):
			queue_free()
		return
	Data.add_score(200)
	ScoreText.new(str(200), self)
	queue_free()
