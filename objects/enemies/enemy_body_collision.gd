extends Area2D

@export_category("Enemy's Body Collision")
@export var solid: bool = true


func _ready() -> void:
	area_entered.connect(func(area: Area2D) -> void:
		if area.get_script() != get_script() || area.owner == owner: return
		if area.owner is GravityBody2D && solid:
			area.owner.turn_x()
	)
