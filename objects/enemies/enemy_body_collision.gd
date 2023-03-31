extends Area2D

@export_category("Enemy's Body Collision")
@export var solid: bool = true
@export var turn_back: bool = true


func _ready() -> void:
	area_entered.connect(
		func(area: Area2D) -> void:
			if area.get_script() != get_script() || area.owner == owner: return
			if owner is GravityBody2D && area.solid && turn_back:
				owner.turn_x()
	)
