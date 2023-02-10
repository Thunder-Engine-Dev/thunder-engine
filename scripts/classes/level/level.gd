# Base level node

@tool
@icon("./icon.svg")
extends Stage2D
class_name Level

@export var time: int = 360

@export_enum("Nothing", "Death", "Wrap") var falling_below_screen_action: int = 1


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		if get_child_count() == 0:
			prepare_template()
		
		return
	
	Data.values.time = time

# Adding neccessary nodes to our level scene
func prepare_template() -> void:
	var player = load("res://engine/nodes/core/player/player.tscn").instantiate()
	add_child(player)
	player.position = Vector2(80, 416)
	player.set_owner(self)
	
	var camera = Camera2D.new()
	camera.set_script(load("res://engine/nodes/core/player/scripts/player_camera_2d.gd"))
	camera.limit_left = 0
	camera.limit_bottom = 480
	camera.limit_top = 0
	add_child(camera)
	camera.set_name('PlayerCamera2D')
	camera.set_owner(self)
	
	var tilemap = TileMap.new()
	tilemap.tile_set = load("res://modules/base/tilesets/placeholder/placeholder_tileset.tres")
	add_child(tilemap, true)
	tilemap.set_cell(0, Vector2i(2, 13), 1, Vector2i.ZERO)
	tilemap.set_owner(self)
	
	var hud = load("res://modules/base/components/hud/hud.tscn").instantiate()
	add_child(hud)
	hud.set_owner(self)


func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	
	if Thunder._current_player.position.y > 512: # TEMP
		match falling_below_screen_action:
			1: Thunder._current_player.kill()
			2: Thunder._current_player.position.y -= 608

