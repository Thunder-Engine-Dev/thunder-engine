extends GeneralMovementBody2D

@export var speed_cap: float = 200
@export var turn_speed: float = 2.5

var speed_modifier: float = 0


func _physics_process(delta: float) -> void:
	super(delta)
	
	update_dir()
	
	speed.x = move_toward(speed.x, speed_cap * dir, abs(turn_speed * dir) * delta * 50)


func set_self_modulate_back() -> void:
	await get_tree().physics_frame
	if is_instance_valid(sprite_node):
		sprite_node.self_modulate.a = 1.0
