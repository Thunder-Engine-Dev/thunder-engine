extends Node

var current_scene:Node
var current_root:Node
var buffered_scenes:Array[Node]

signal scene_changed(to:PackedScene)


# Register scene
func register(scene:Node) -> void:
	current_scene = scene
	if current_scene.is_inside_tree(): current_root = scene.get_parent()


# Install scene
func install_scene() -> void:
	current_root.add_child(current_scene)


# Load scene as current
func load_scene(scene:Node) -> void:
	register(scene)
	install_scene()

func load_scene_from_buffer(buffer_id:int) -> void:
	register(get_buffered_scene(buffer_id))
	install_scene()

func load_scene_from_packed(pck:PackedScene) -> void:
	if !pck: return
	var scene:Node = pck.instantiate()
	load_scene(scene)

func load_scene_from_path(path:String) -> void:
	if path.is_empty(): return
	load_scene_from_packed(load(path) as PackedScene)


# Unload scene
func unload_current_scene() -> void:
	current_scene.queue_free()

func unload_current_scene_as_buffer(buffer_id:int) -> void:
	buffer_scene(current_scene,buffer_id)
	current_scene.get_parent().remove_child(current_scene)


# Switch to scene
func switch_to_scene(to:Node) -> void:
	unload_current_scene()
	load_scene(to)

func switch_to_scene_packed(pck:PackedScene) -> void:
	unload_current_scene()
	load_scene_from_packed(pck)


# Reload current scene 重载当前场景
func reload_current_scene() -> void:
	var path:String = current_scene.scene_file_path
	unload_current_scene()
	load_scene_from_path(path)

func reload_current_game() -> void:
	get_tree().reload_current_scene()


# Buffer scene
func buffer_scene(scene:Node,id:int) -> void:
	if id < 0: return
	if buffered_scenes.size() > id + 1: buffered_scenes.resize(id + 1)
	buffered_scenes[id] = scene

# Clear buffered scene
func clear_buffered_scene(id:int) -> void:
	if abs(id + 1) > buffered_scenes.size(): return
	buffered_scenes[id] = null

func clear_all_buffered_scenes() -> void:
	buffered_scenes.clear()

# Get buffered scene 
func get_buffered_scene(id:int) -> Node:
	if buffered_scenes.size() > id + 1: return null
	return buffered_scenes[id]
