extends AnimatableBody2D

@onready var base: Control = get_parent()
@onready var shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	update()


func update() -> void:
	var length = base.get_rect().size
	shape.scale = length
	shape.position.y = sign(base.get_transform().get_scale().y) * length.y / 2
	shape.position.x = sign(base.get_transform().get_scale().x) * length.x / 2
