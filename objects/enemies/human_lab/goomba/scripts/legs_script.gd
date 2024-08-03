extends AnimatedSprite2D

const EnemyKilled: Script = preload("res://engine/objects/enemies/_dead/enemy_killed.gd")

@export var enemy_center_node: NodePath
@export var can_idle: bool = false
@export var can_move_both_ways: bool = false
@export var idle_offset: Vector2
@export var walk_offset: Vector2

@onready var parent = $'..'
@onready var _center: GravityBody2D = get_node_or_null(enemy_center_node)

func _physics_process(delta: float) -> void:
	flip_h = parent.flip_h
	offset = (idle_offset if is_zero_approx(_center.speed.x) else walk_offset) * sign(_center.speed.x)
	
	if _center == null || _center is EnemyKilled:
		animation = "idle"
		return

	if can_idle:
		animation = "idle" if is_zero_approx(_center.speed.x) else "default"
	if can_move_both_ways:
		speed_scale = sign(_center.speed.x) * (-1 if flip_h else 1)
	
