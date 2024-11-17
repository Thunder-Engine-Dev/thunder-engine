extends GravityBody2D
class_name GeneralMovementBody2D

##
##
##

##
@export var look_at_player: bool
## -1 is Left, 1 is Right.
@export_enum("Disabled: 0", "Left: -1", "Right: 1") var force_direction: int = 0
##
@export var turn_sprite: bool = true
##
@export var slide: bool
@export_group("References")
##
@export var sprite: NodePath

var dir: int

@onready var sprite_node: Node2D = get_node_or_null(sprite)


func _ready() -> void:
	if Engine.is_editor_hint(): return
	super()
	
	# Fix misdetection of being on wall when sloping down
	floor_max_angle += PI/180
	
	if force_direction:
		dir = force_direction
		speed_to_dir()
		return
	
	if look_at_player && Thunder._current_player:
		update_dir.call_deferred()
		speed_to_dir.call_deferred()


func _physics_process(delta: float) -> void:
	motion_process(delta, slide)
	if turn_sprite && sprite_node && is_instance_valid(sprite_node):
		sprite_node.flip_h = speed.x < 0


func update_dir() -> void:
	var player: Player = Thunder._current_player
	if !player: return
	dir = Thunder.Math.look_at(global_position, player.global_position, global_transform)
	if dir == 0: dir = -1


func speed_to_dir() -> void:
	speed.x = abs(speed.x) * dir
