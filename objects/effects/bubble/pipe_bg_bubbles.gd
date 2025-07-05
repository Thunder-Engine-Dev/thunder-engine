extends Marker2D

const BUBBLE_BG = preload("res://engine/objects/effects/bubble/bubble_bg.tscn")
@export var radius_x: float = 20
@export var gen_z_index: int = -30

var counter: float = 0
var count_to: float = 0

func _physics_process(delta: float) -> void:
	if !Thunder.view.is_getting_closer(self, 128):
		return
	counter += delta
	if counter > count_to:
		count_to = randf_range(0.4, 2.0)
		counter = 0
		var buble = BUBBLE_BG.instantiate()
		buble.speed = Vector2.UP.rotated(global_rotation) * randf_range(40, 250)
		buble.position.x = randf_range(-radius_x, radius_x)
		buble.z_index = gen_z_index
		add_child(buble)
