@tool
extends Node2D

@export_category("Fireball Firebar")
@export var belongs_to: Data.PROJECTILE_BELONGS = Data.PROJECTILE_BELONGS.ENEMY
@export_group("Preview")
@export var preview: bool:
	set(value):
		preview = value
		
		if !Engine.is_editor_hint():
			return
		
		set_process(preview)
		set_physics_process(preview)
@export_group("Physics")
@export_range(0, 1, 0.001, "or_greater", "hide_slider", "suffix:px") var radius: float = 50
@export_range(-18000, 18000, 0.001, "suffix:°/s") var angular_speed: float = 50
@export_range(-180, 180, 0.001, "degrees") var angle: float:
	set(value):
		angle = value
		if is_node_ready():
			_set_position_angular()
@export_group("Animation")
@export_range(-18000, 18000, 0.001, "suffix:°/s") var sprite_rotation_speed: float = 500:
	set(value):
		sprite_rotation_speed = value
		$Sprite.flip_h = sprite_rotation_speed < 0

@onready var _origin: Vector2 = position
@onready var _sprite: Sprite2D = $Sprite

func _ready() -> void:
	preview = preview
	_set_position_angular()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_sprite = $Sprite
	_sprite.rotate(deg_to_rad(sprite_rotation_speed * delta))

func _physics_process(delta: float) -> void:
	_set_position_angular()
	angle = wrapf(angle + angular_speed * delta, -180, 180)


func _set_position_angular() -> void:
	position = _origin + radius * Vector2.RIGHT.rotated(deg_to_rad(angle))
