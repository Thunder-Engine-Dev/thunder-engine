extends GeneralMovementBody2D
class_name Projectile

@export var belongs_to: Data.PROJECTILE_BELONGS = Data.PROJECTILE_BELONGS.PLAYER


func _ready() -> void:
	add_to_group(&"end_level_sequence")
	super()


## ABSTRACT METHOD
func _on_level_end() -> void:
	pass
