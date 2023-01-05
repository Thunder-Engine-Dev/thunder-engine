extends GravityBody2D

@export_category("GeneralMovementEnemy")
@export var look_at_player: bool = false
@export var turn_on_wall: bool = true


func _ready() -> void:
	if look_at_player && Thunder._current_player:
		velocity_local.x *= global_transform.affine_inverse().basis_xform(global_position.direction_to(Thunder._current_player.global_position).sign()).x
	
	connect("collided_wall", self.turn)

func _physics_process(delta: float) -> void:
	gravity_process(Thunder.get_delta(delta))
	motion_process(Thunder.get_delta(delta),false)

func turn() -> void:
	velocity_local.x = -velocity_local.x
