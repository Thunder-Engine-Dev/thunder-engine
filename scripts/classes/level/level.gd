@tool
@icon("./icon.svg")
extends Stage2D
class_name Level

## Base level node[br]
## Once you selected this node via [b]Create Node Pannel[/b] it will automatically deploy the basic template
## of a level, which is more convenient to structure a level from zero.

## Emitted when player completes the level
signal level_completed

## Rest time of the level. If going to [color=red]0[/color], the player alive will be killed in force.
@export var time: int = 360
@export var enable_restart_in_pause: bool = true

@export_group("Level Completion")
## Level completion music
@export var completion_music: AudioStream = preload("res://engine/scripts/classes/level/complete.ogg")
## Write info about level completion to save file
@export var completion_write_save: bool = true
## Override scene path that gets written to save file
@export var completion_write_save_path_override: String = ""
## Jump to scene after level completion sequence
@export_file("*.tscn", "*.scn") var jump_to_scene: String
## If you have a weird misplaced circle transition after jumping to next scene, enable this property
@export var completion_center_on_player_after_transition: bool = false

@export_group("Player's Falling Below", "falling_below_")
## Enum to decide the bahavior when a player falls from the bottom of the screen[br]
## 0 = Nothing[br]
## 1 = Death[br]
## 2 = Wrap from top of the screen[br]
## 3 = Trigger pipe warp
@export_enum("Nothing", "Death", "Wrap", "Pipe Warp") var falling_below_screen_action: int = 1
## Modifies the bottom line that detect player as "falling below the screen"
@export var falling_below_y_offset: float = 64.0
## Warp out node, if Screen Action is set to Pipe Warp
@export_node_path("Area2D") var falling_below_warp_to: NodePath

@onready var falling_below_warp_target: Area2D = get_node_or_null(falling_below_warp_to)

# Forces player to walk forward, used in finish sequence
var _force_player_walking: bool = false
var _force_player_walking_dir: int = 1:
	set(dir):
		_force_player_walking_dir = clampi(dir, -1, 1)
		if dir == 0:
			dir = [-1, 1].pick_random()
var _forced_player_on_wall: bool

var completed: bool

func _ready() -> void:
	if Engine.is_editor_hint():
		if get_child_count() == 0:
			_prepare_template()
		return
	
	Data.values.time = time
	
	super()

# Adding neccessary nodes to our level scene
func _prepare_template() -> void:
	var music_loader = load("res://engine/objects/core/music_loader/music_loader.tscn").instantiate()
	add_child(music_loader)
	music_loader.set_owner(self)
	
	var player = load("res://engine/objects/players/mario/mario.tscn").instantiate()
	add_child(player)
	player.position = Vector2(80, 400)
	player.set_owner(self)
	
	var camera = Camera2D.new()
	camera.set_script(load("res://engine/objects/players/player_camera_2d.gd"))
	camera.editor_draw_screen = false
	add_child(camera)
	camera.set_name('PlayerCamera2D')
	camera.set_owner(self)
	camera.set_meta(&"_edit_lock_", true)
	
	# Camera limits
	var cam_area = load("res://engine/components/cam_area/cam_area.tscn").instantiate()
	add_child(cam_area)
	cam_area.size = Vector2(11008, 480)
	cam_area.set_name('CameraArea')
	cam_area.set_owner(self)
	cam_area.set_meta(&"_edit_lock_", true)
	
	# Setting up tileset for the TileMap
	var tileset = TileSet.new()
	tileset.tile_size = Vector2(32, 32)
	tileset.add_physics_layer(0)
	tileset.set_physics_layer_collision_layer(0, 0b1110000)
	tileset.set_physics_layer_collision_mask(0, 0)
	var tileset_source = TileSetAtlasSource.new()
	tileset_source.texture = load("res://engine/tilesets/overworld/hard_block.png")
	tileset_source.texture_region_size = Vector2(32, 32)
	tileset_source.create_tile(Vector2i.ZERO)
	tileset.add_source(tileset_source)
	var tile_data = tileset_source.get_tile_data(Vector2i.ZERO, 0)
	var polygons_array := PackedVector2Array(
		[Vector2.ONE * -16, Vector2(1, -1) * 16, Vector2.ONE * 16, Vector2(-1, 1) * 16]
	)
	tile_data.add_collision_polygon(0)
	tile_data.set_collision_polygon_points(0, 0, polygons_array)
	
	# Adding TileMap with tileset we defined above
	var tilemap = TileMap.new()
	tilemap.tile_set = tileset
	add_child(tilemap, true)
	tilemap.set_cell(0, Vector2i(2, 13), 0, Vector2i.ZERO)
	tilemap.set_owner(self)
	tilemap.set_meta(&"_edit_lock_", true)
	
	var hud = load("res://engine/components/hud/hud.tscn").instantiate()
	add_child(hud)
	hud.set_owner(self)
	
	var parallax_bg = ParallaxBackground.new()
	add_child(parallax_bg, true)
	parallax_bg.set_owner(self)
	
	var folder = Node2D.new()
	add_child(folder)
	folder.set_name('Objects')
	folder.set_owner(self)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var player: Player = Thunder._current_player
	if !player: return
	
	# Force player walking when completed
	if _force_player_walking && !_forced_player_on_wall:
		player.direction = _force_player_walking_dir
		player.speed.x = 120 * player.direction
		_forced_player_on_wall = player.is_on_wall()
		if _forced_player_on_wall:
			player.speed.x = 0
	
	# Falling behavior
	if !player || !_is_stage_ready:
		return
	if !Thunder.view.screen_bottom(player.global_position, falling_below_y_offset - 16):
		match falling_below_screen_action:
			1: player.die()
			2: player.position.y -= 608
			3: 
				assert(falling_below_warp_target && falling_below_warp_target.has_method("pass_player"),
				"ERROR: falling_below_warp_target contains an invalid Out Warp")
				
				player.speed = Vector2.ZERO
				falling_below_warp_target.pass_player(player)


func finish(walking: bool = false, walking_dir: int = 1) -> void:
	if !Thunder._current_player: return
	level_completed.emit()
	print("[Game] Level complete.")
	
	Thunder._current_hud.timer.paused = true
	Thunder._current_player.completed = true
	Audio.stop_all_musics()
	if completion_music:
		Audio.play_music(completion_music, -1)
	
	if walking: 
		_force_player_walking = true
		_force_player_walking_dir = walking_dir
	Data.values.onetime_blocks = true
	Thunder._current_player.left_right = 0
	
	get_tree().call_group_flags(
		get_tree().GROUP_CALL_DEFERRED,
		&"end_level_sequence",
		&"_on_level_end"
	)
	
	await get_tree().process_frame
	if completion_music:
		await Audio._music_channels[-1].finished
	
	Thunder._current_hud.time_countdown_finished.connect(
		func() -> void:
			await get_tree().create_timer(0.8, false, false).timeout
			var _crossfade: bool = SettingsManager.get_tweak("replace_circle_transitions_with_fades", false)
			Data.values.checkpoint = -1
			Data.values.checked_cps = []
			
			if jump_to_scene:
				if !_crossfade:
					TransitionManager.accept_transition(
						load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
							.instantiate()
							.with_speeds(0.04, -0.1)
							.with_pause()
							.on_player_after_middle(completion_center_on_player_after_transition)
					)
					
					await TransitionManager.transition_middle
					Scenes.goto_scene(jump_to_scene)
				else:
					TransitionManager.accept_transition(
						load("res://engine/components/transitions/crossfade_transition/crossfade_transition.tscn")
							.instantiate()
							.with_scene(jump_to_scene)
					)
			else:
				printerr("[Level] Jump to scene is not defined in the level.")
	)
	
	if completion_write_save:
		var profile = ProfileManager.current_profile
		var path = scene_file_path if !completion_write_save_path_override else completion_write_save_path_override
		if !profile.has_completed(path):
			profile.complete_level(path)
			ProfileManager.save_current_profile()
	
	Thunder._current_hud.time_countdown()
