@tool
extends GeneralMovementBody2D

signal stun

@export_group("Basic")
@export var texture: Texture2D
@export var trigger_area: Rect2 = Rect2(Vector2(-80, -32), Vector2(160, 480))
@export var stunning_sound: AudioStream = preload("res://engine/objects/projectiles/sounds/stun.wav")
@export var rotation_speed: float = 12

var _step: int
var _vel: Vector2
var _origin: Vector2

@onready var collision_shape_2d: CollisionShape2D = $Body/CollisionShape2D

func _ready() -> void:
	if texture:
		$Sprite.texture = texture


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	match _step:
		# Waiting
		0:
			var player: Player = Thunder._current_player
			if !player: return
			var ppos: Vector2 = global_transform.affine_inverse() * player.global_position
			if trigger_area.has_point(ppos):
				_origin = global_position
				_step = 1
		# Stunning
		1:
			_stun()
			_vel = velocity.normalized()
			_step = 2
		2:
			motion_process(delta)
			sprite_node.rotation_degrees += rotation_speed * delta * 50
			collision_shape_2d.global_rotation = sprite_node.global_rotation
			

func _stun() -> void:
	stun.emit()
	Audio.play_sound(stunning_sound, self)
	if Thunder._current_camera.has_method(&"shock"):
		Thunder._current_camera.shock(0.1, Vector2.ONE * 2)

