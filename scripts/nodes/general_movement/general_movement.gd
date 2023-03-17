extends GravityBody2D
class_name GeneralMovementBody2D

@export_category("GeneralMovement")
@export var look_at_player: bool
@export var turn_sprite: bool = true
@export var deep_snap: bool = true
@export var kinematic_movement: bool = true
@export_category("References")
@export var sprite: NodePath

var dir: int


func _ready() -> void:
	super()
	
	if look_at_player && Thunder._current_player:
		update_dir()
		speed.x *= dir

func _physics_process(delta: float) -> void:
	motion_process(Thunder.get_delta(delta), deep_snap, kinematic_movement)
	
	var sprite_node = get_node_or_null(sprite)
	if turn_sprite && sprite_node:
		sprite_node.flip_h = speed.x < 0


func update_dir() -> void:
	dir = (global_transform.affine_inverse().basis_xform(global_position.direction_to(Thunder._current_player.global_position))).sign().x
