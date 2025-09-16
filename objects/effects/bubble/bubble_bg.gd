extends Area2D

@export var speed: Vector2

var _cracked: bool
var _start: bool

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	_start = true


func _physics_process(delta: float) -> void:
	if !Thunder.view.is_getting_closer(self, 128):
		queue_free()
	
	if !_cracked:
		global_position += speed * delta
	else:
		return
	
	if !_start:
		return
	
	_cracked = false
	for i in get_overlapping_areas():
		if i.is_in_group(&"#no_bubbles"):
			queue_free()
			return
		if i.is_in_group(&"#crack_bubbles"):
			_cracked = true
	if _cracked:
		break_bubble()


func break_bubble() -> void:
	sprite.play(&"destroy")
	sprite.animation_finished.connect(queue_free, CONNECT_REFERENCE_COUNTED)
