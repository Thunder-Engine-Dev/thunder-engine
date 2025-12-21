extends Node

@export var cheep_scene: PackedScene = preload("res://engine/objects/enemies/cheeps/cheep_red_jumping.tscn")
@export var enabled: bool = true

@export_subgroup("Spawn rate")
@export var random_pool: int = 20
@export var random_equals: int = 10
@export var chance_every_sec: float = 0.1
@export var max_on_screen: int = 10
@export_subgroup("Cheep spawn speed")
@export var speed_min := Vector2i(-7 * 50, -8 * 50)
@export var speed_max := Vector2i(-1 * 50, -5 * 50)

func _ready() -> void:
	_time()

func _time() -> void:
	await get_tree().create_timer(chance_every_sec, false).timeout
	_time()
	
	if !enabled: return
	if Data.values.stopwatch > 0: return
	if Thunder._current_player && Thunder._current_player.completed: return
	
	if Thunder.rng.get_randi_range(0, random_pool) == random_equals:
		if get_tree().get_node_count_in_group("obj_by_" + str(get_instance_id())) >= max_on_screen:
			return
		Thunder.view.cam_border()
		var to_pos = Vector2(Thunder.view.border.end) + Vector2(Thunder.rng.get_randi_range(-100, 0), 0)
		
		var fish = cheep_scene.instantiate()
		fish.global_position = to_pos
		fish.reset_physics_interpolation()
		fish.speed.x = Thunder.rng.get_randi_range(speed_min.x, speed_max.x)
		fish.speed.y = Thunder.rng.get_randi_range(speed_min.y, speed_max.y)
		fish.life_time = 2.0
		fish.add_to_group("obj_by_" + str(get_instance_id()))
		Scenes.current_scene.add_child(fish)

func enable() -> void:
	enabled = true

func disable() -> void:
	enabled = false
