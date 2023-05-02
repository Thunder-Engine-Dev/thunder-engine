extends AnimatableBody2D


@onready var par: HBoxContainer = get_parent() as HBoxContainer


func _ready() -> void:
	position = par.get_rect().get_center()
	scale = par.get_rect().size
