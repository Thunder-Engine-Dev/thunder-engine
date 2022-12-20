extends GravityBody2D

@export_category("GeneralMovementEnemy")


func _physics_process(delta: float) -> void:
	motion_process(Thunder.get_delta(delta))
	collision_process()
