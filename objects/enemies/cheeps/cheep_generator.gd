extends Node

@export var cheep: = preload("res://engine/objects/enemies/cheeps/cheep_red.tscn")
@export_enum("Left: -1", "Right: 1") var direction: int = 1
@export var active: bool = true
@export_subgroup("Spawning")
@export var delay_sec: float = 2
@export var delay_stopped_sec: float = 3.5
@export var min_offset_y: int = -128
@export var max_offset_y: int = 192
@export var max_on_screen: int = 10
@export_subgroup("Spawned Instance settings")
@export var custom_vision_rect := Rect2(-32, -24, 64, 48)

var timer: float

func _physics_process(delta):
	if !active: return
	var cam = Thunder._current_camera
	if !cam: return
	var player = Thunder._current_player
	if !player: return
	
	if get_tree().get_node_count_in_group("obj_by_" + str(get_instance_id())) >= max_on_screen:
		return
	
	timer += delta
	var is_moving: bool = player && player.speed.x > 20
	if timer < (delay_sec if is_moving else delay_stopped_sec): return
	timer = 0
	
	if (player.speed.x < -1 && direction > 0) || (player.speed.x > 1 && direction < 0): return
	
	var inst = cheep.instantiate()
	#inst.look_at_player = false
	Scenes.current_scene.add_child(inst)
	inst.global_position = Vector2(
		cam.get_screen_center_position().x + 340 * direction,
		cam.get_screen_center_position().y + Thunder.rng.get_randi_range(min_offset_y, max_offset_y)
	)
	inst.reset_physics_interpolation()
	inst.add_to_group("obj_by_" + str(get_instance_id()))
	inst.is_spawned = true
	if !custom_vision_rect: return
	var vis = Thunder.get_child_by_class_name(inst, "VisibleOnScreenEnabler2D")
	if vis:
		vis.rect = custom_vision_rect
		vis.new_rect = custom_vision_rect


func enable() -> void:
	active = true

func disable() -> void:
	active = false
