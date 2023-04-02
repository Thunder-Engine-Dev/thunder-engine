extends GravityBody2D
class_name GeneralMovementBody2D

@export_category("GeneralMovement")
@export var look_at_player: bool
@export var turn_sprite: bool = true
@export var slide: bool
@export_category("References")
@export var sprite: NodePath

var dir: int


func _ready() -> void:
	super()
	
	if look_at_player && Thunder._current_player:
		update_dir()
		speed.x *= dir


func _physics_process(delta: float) -> void:
	motion_process(Thunder.get_delta(delta), slide)
	
	var sprite_node = get_node_or_null(sprite)
	if turn_sprite && sprite_node:
		sprite_node.flip_h = speed.x < 0


func update_dir() -> void:
	dir = int((global_transform.affine_inverse().basis_xform(global_position.direction_to(Thunder._current_player.global_position))).sign().x)
