extends AnimatedSprite2D

const EnemyKilled: Script = preload("res://engine/objects/enemies/_dead/enemy_killed.gd")

@export_node_path("Node2D") var enemy_center_node: NodePath
@export_node_path("Node2D") var parent_sprite: NodePath = ^".."
@export var can_idle: bool = false
@export var can_move_both_ways: bool = false
@export var can_jump: bool = false
@export_enum("Speed X","Flip H") var flip_method: int = 0
@export var idle_offset: Vector2
@export var walk_offset: Vector2
@export var jump_offset: Vector2

@onready var parent: Node2D = get_node(parent_sprite)
@onready var _center: GravityBody2D = get_node_or_null(enemy_center_node)

func _physics_process(delta: float) -> void:
	flip_h = parent.flip_h
	var flipping: int
	if flip_method == 0:
		flipping = sign(_center.speed.x)
	else:
		flipping = -1 if flip_h else 1
	offset = (idle_offset if is_zero_approx(_center.speed.x) else walk_offset) * flipping
	
	if _center == null || _center is EnemyKilled:
		play(&"idle")
		speed_scale = 1
		return
	
	if can_jump && !_center.is_on_floor():
		if animation != "jump":
			play(&"jump")
		speed_scale = 1
		offset = jump_offset * flipping
		return

	if can_idle:
		play(&"idle" if is_zero_approx(_center.speed.x) else &"default")
	if can_move_both_ways:
		speed_scale = sign(_center.speed.x) * (-1 if flip_h else 1)
	
