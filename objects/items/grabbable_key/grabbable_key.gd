extends GeneralMovementBody2D

@export_range(0, 99999, 0.1, "or_greater", "hide_slider", "suffix:px/s²") var deceleration: float = 400

@onready var _attack: ShapeCast2D = $Attack

var enemy_hold_position: Vector2


func _physics_process(delta: float) -> void:
	super(delta)
	_attack.enabled = velocity.length_squared() > 784
	
	speed.x = move_toward(speed.x, 0, deceleration * delta)


func _on_grab_initiated() -> void:
	disable_mode = CollisionObject2D.DISABLE_MODE_REMOVE


func _on_enemy_owner_died() -> void:
	_attack.belongs_to = Data.PROJECTILE_BELONGS.PLAYER

func grabbable_get_enemy_hold_global_position() -> Vector2:
	return enemy_hold_position if enemy_hold_position else global_position

#func _on_ungrabbed() -> void:
	#z_index = old_z_index
	#_attack.enabled = true
#
#
#func _on_grabbed() -> void:
	#old_z_index = z_index
	#z_index = 1
	#_attack.enabled = false
