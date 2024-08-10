extends Node

@export var center: NodePath = ^".."
@export var jump_strength: float = 350
@onready var _center: Powerup = get_node_or_null(center)
@onready var _tweak: bool = SettingsManager.get_tweak("brick_bumping_mushrooms", false)

func set_bump() -> void:
	if !_tweak: return
	if !_center: return
	if !_center.appear_distance && _center.speed.y > -1:
		_center.jump(jump_strength)
		_center.turn_x()
