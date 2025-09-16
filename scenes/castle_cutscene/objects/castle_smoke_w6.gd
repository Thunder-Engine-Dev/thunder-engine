extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@export var target_pos := Vector2(174, 458)

const MAX_SPEED: float = 625.0
var speed: float = 0

func _ready() -> void:
	position.x = target_pos.x + randi_range(-256, 256)
	position.y = 394 + randi_range(-64, 0)
	var tw = create_tween()
	tw.tween_property(sprite, "scale", Vector2.ONE, 0.5)
	await tw.finished
	var tw2 = create_tween().set_loops().set_trans(Tween.TRANS_CUBIC)
	tw2.tween_property(sprite, "scale", Vector2(0.85, 0.85), 0.08).set_ease(Tween.EASE_IN)
	tw2.tween_property(sprite, "scale", Vector2.ONE, 0.08).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float) -> void:
	position.y -= delta * 150
	#sprite.global_rotation = 0
	
	speed += 312.5 * delta
	speed = minf(speed, 625.0)
	#rotation = target_pos.angle_to_point(position)
	position = position.move_toward(target_pos, speed * delta)
	if (
		position.x > abs(target_pos.x) - 2 &&
		position.y > abs(target_pos.y) - 2
	):
		queue_free()
