extends AnimatableBody2D

@onready var base: Control = get_parent()
@onready var shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	update()


func update() -> void:
	var length: float = base.get_rect().size.y
	shape.scale.y = length
	shape.position.y = sign(base.get_transform().get_scale().y) * length / 2
