extends AnimatedSprite2D

@export var speed: float = 8
@export var teleport_by: float = 736

@onready var init_pos = position.x

func _physics_process(delta: float):
	var cam: Camera2D = Thunder._current_camera as Camera2D
	if !cam: return
	position.x -= speed * delta
	var cam_pos: float = cam.get_screen_center_position().x

	while position.x >= cam_pos + 320 + 32:
		position.x -= teleport_by
	while position.x < cam_pos - 320 - 32:
		position.x += teleport_by


func disappear() -> void:
	var tw = create_tween()
	tw.tween_interval(randf_range(0.1, 3.0))
	tw.tween_property(self, "modulate:a", 0.0, 2.0)
	tw.tween_callback(queue_free)
