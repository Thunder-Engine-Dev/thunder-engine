extends Marker2D

const BUBBLE_BG = preload("res://engine/objects/effects/bubble/bubble_bg.tscn")
@export var radius_x: float = 20
@export var gen_z_index: int = -30
@export var min_speed: float = 40
@export var max_speed: float = 250
@export var delay_range_sec := Vector2(0.4, 2.0)

var counter: float = 0
var count_to: float = 0

func _physics_process(delta: float) -> void:
	if !Thunder.view.is_getting_closer(self, 128):
		return
	counter += delta
	if counter > count_to:
		count_to = randf_range(delay_range_sec.x, delay_range_sec.y)
		counter = 0
		var buble = BUBBLE_BG.instantiate()
		buble.speed = Vector2.UP.rotated(global_rotation) * randf_range(min_speed, max_speed)
		buble.position.x = randf_range(-radius_x, radius_x)
		buble.z_index = gen_z_index
		add_child(buble)
