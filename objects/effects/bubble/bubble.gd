extends Area2D

var _cracked: bool
var _start: bool

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	_start = true


func _physics_process(delta: float) -> void:
	if !Thunder.view.is_getting_closer(self, 32):
		queue_free()
	
	if !_cracked:
		global_position += Vector2.UP.rotated(global_rotation) * randi_range(0, 100) * delta
		position.x += randf_range(-100,100) * delta
	
	if !_start:
		return
	
	_cracked = true
	for i in get_overlapping_areas():
		if i.is_in_group(&"#water"):
			_cracked = false
			return
	if _cracked:
		break_bubble()


func break_bubble() -> void:
	sprite.play(&"destroy")
	sprite.animation_finished.connect(queue_free, CONNECT_REFERENCE_COUNTED)
