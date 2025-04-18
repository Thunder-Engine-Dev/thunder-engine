extends Node

@export var cheep: = preload("res://engine/objects/enemies/cheeps/cheep_red.tscn")
@export_enum("Left: -1", "Right: 1") var direction: int = 1
@export var active: bool = true
@export var delay_sec: float = 2
@export var delay_stopped_sec: float = 3.5

var timer: float

func _physics_process(delta):
	if !active: return
	var cam = Thunder._current_camera
	if !cam: return
	var player = Thunder._current_player
	if !player: return
	
	timer += delta
	var is_moving: bool = player && player.speed.x > 20
	if timer < (delay_sec if is_moving else delay_stopped_sec): return
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
	inst.is_spawned = true


func enable() -> void:
	active = true

func disable() -> void:
	active = false
