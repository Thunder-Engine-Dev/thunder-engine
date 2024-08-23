extends Node

@export var cheep: = preload("res://engine/objects/enemies/cheeps/cheep_red.tscn")
@export_enum("Left: -1", "Right: 1") var direction: int = 1
@export var active: bool = true

var timer: float

func _physics_process(delta):
	if !active: return
	var cam = Thunder._current_camera
	if !cam: return
	var player = Thunder._current_player
	if !player: return
	
	timer += delta
	if timer < 2: return
	timer = 0
	
	if player.speed.x < -1: return
	
	var inst = cheep.instantiate()
	inst.look_at_player = false
	Scenes.current_scene.add_child(inst)
	inst.global_position = Vector2(
		cam.get_screen_center_position().x + 340 * direction,
		cam.get_screen_center_position().y + randi_range(-128, 192)
	)
	inst.reset_physics_interpolation()

func enable() -> void:
	active = true

func disable() -> void:
	active = false
