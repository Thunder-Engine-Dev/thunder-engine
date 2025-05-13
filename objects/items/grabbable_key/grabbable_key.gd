extends GeneralMovementBody2D

var old_z_index: int

@export_range(0, 99999, 0.1, "or_greater", "hide_slider", "suffix:px/s²") var deceleration: float = 400

@onready var _attack: ShapeCast2D = $Attack

func _physics_process(delta: float) -> void:
	super(delta)
	_attack.enabled = !is_zero_approx(velocity.length_squared())
	
	speed.x = move_toward(speed.x, 0, deceleration * delta)


func _on_grab_initiated() -> void:
	disable_mode = CollisionObject2D.DISABLE_MODE_REMOVE

func _on_ungrabbed() -> void:
	z_index = old_z_index
	_attack.enabled = true


func _on_grabbed() -> void:
	old_z_index = z_index
	z_index = 1
	_attack.enabled = false
