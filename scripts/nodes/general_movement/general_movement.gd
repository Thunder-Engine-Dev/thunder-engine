extends GravityBody2D
class_name GeneralMovementBody2D

@export_category("GeneralMovement")
@export var look_at_player: bool
@export var turn_sprite: bool = true
@export var slide: bool
@export_category("References")
@export var sprite: NodePath

var dir: int

@onready var sprite_node: Node2D = get_node_or_null(sprite)


func _ready() -> void:
	if Engine.is_editor_hint(): return
	super()
	
	# Fix misdetection of being on wall when sloping down
	floor_max_angle += PI/180
	
	if look_at_player && Thunder._current_player:
		update_dir()
		speed_to_dir()


func _physics_process(delta: float) -> void:
	motion_process(delta, slide)
	if turn_sprite && sprite_node:
		sprite_node.flip_h = speed.x < 0


func update_dir() -> void:
	var player: Player = Thunder._current_player
	if !player: return
	dir = Thunder.Math.look_at(global_position, Thunder._current_player.global_position, global_transform)


func speed_to_dir() -> void:
	speed.x *= dir
