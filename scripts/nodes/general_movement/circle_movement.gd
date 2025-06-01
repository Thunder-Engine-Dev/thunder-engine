extends Node2D

enum FacingMethod {
	LOOK_AT_PLAYER,
	X_SINE,
	Y_COSINE
}

@export_group("Physics")
@export var amplitude: Vector2 = Vector2(50, 50)
@export_range(0, 360, 0.01, "suffix: °") var phase: float
@export var random_phase: bool:
	set(rph):
		random_phase = rph
		if random_phase:
			phase = Thunder.rng.get_randf_range(0, 360)
@export var frequency: float = 1
@export_group("Sprite")
@export var sprite_path: NodePath
@export var facing_method: FacingMethod = FacingMethod.LOOK_AT_PLAYER

var dir: int
var facing: float

@onready var center: Vector2 = position

func _ready() -> void:
	_physics_process(0)


func _physics_process(delta: float) -> void:
	position = Thunder.Math.oval(center, amplitude, deg_to_rad(phase))
	phase = wrapf(phase + frequency * Thunder.get_delta(delta), 0, 360)
	
	if !sprite_path || !has_node(sprite_path):
		return
	var sprite = get_node(sprite_path)
	
	match facing_method:
		FacingMethod.LOOK_AT_PLAYER:
			var player: Player = Thunder._current_player
			if player:
				facing = Thunder.Math.look_at(global_position, player.global_position, global_transform)
		FacingMethod.X_SINE:
			facing = -sin(deg_to_rad(phase))
		FacingMethod.Y_COSINE:
			facing = cos(deg_to_rad(phase))
	dir = sign(facing)
	
	if &"flip_h" in sprite:
		sprite.flip_h = (facing < 0 && facing != 0)
