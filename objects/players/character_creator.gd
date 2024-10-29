extends GravityBody2D

signal suit_appeared
signal suit_changed(to: PlayerSuit)
signal swam
signal shot
signal threw
signal grab_init(node: Node2D)
signal grabbed(side_grabbed: bool)
signal invinciblized(dur: float)
signal starmaned(dur: float)
signal starman_attacked
signal damaged
signal died
signal died_with_body(dead_player_body: Node2D)

@export_group("Physics")
@export_enum("Left: -1", "Right: 1") var direction: int = 1:
	set(to):
		direction = to
		if !direction in [-1, 1]:
			direction = [-1, 1].pick_random()
@export_group("Death", "death_")
@export var death_sprite: Node2D
@export var death_body: PackedScene = preload("res://engine/objects/players/deaths/player_death.tscn")
@export var death_music_override: AudioStream
@export var death_music_ignore_pause: bool = false
@export var death_wait_time: float = 3.5
@export var death_check_for_lives: bool = true
## Specify where to go after player's death. Leave empty to restart the current scene.
@export_file("*.tscn", "*.scn") var death_jump_to_scene: String = ""
@export var death_stop_music: bool = true


func _ready() -> void:
	var player: Player = CharacterManager.get_player_packed_scene().instantiate()
	player.transform = transform
	add_sibling.call_deferred(player)
	if !Thunder._current_player:
		Thunder._current_player = player
	
	player.direction = direction
	if death_sprite:
		player.death_sprite = death_sprite
	player.death_body = death_body
	player.death_music_override = death_music_override
	player.death_music_ignore_pause = death_music_ignore_pause
	player.death_wait_time = death_wait_time
	player.death_check_for_lives = death_check_for_lives
	player.death_jump_to_scene = death_jump_to_scene
	player.death_stop_music = death_stop_music
	
	player.speed = speed
	player.gravity_dir = gravity_dir
	player.gravity_dir_rotation = gravity_dir_rotation
	player.gravity_scale = gravity_scale
	player.max_falling_speed = max_falling_speed
	player.collision = collision
	player.vertical_correction_amount = vertical_correction_amount
	player.horizontal_correction_amount = horizontal_correction_amount
	player.correct_collision = correct_collision
	
	player.motion_mode = motion_mode
	player.up_direction = up_direction
	player.slide_on_ceiling = slide_on_ceiling
	player.floor_stop_on_slope = floor_stop_on_slope
	player.floor_constant_speed = floor_constant_speed
	player.floor_block_on_wall = floor_block_on_wall
	player.floor_max_angle = floor_max_angle
	player.floor_snap_length = floor_snap_length
	
	player.collision_layer = collision_layer
	player.collision_mask = collision_mask
	player.modulate = modulate
	player.visible = visible
	player.z_index = z_index
	
	for sig_dict in get_signal_list():
		for connection in get_signal_connection_list(sig_dict.name):
			Thunder._connect(connection.signal, connection.callable, connection.flags)
	
	queue_free.call_deferred()
	
