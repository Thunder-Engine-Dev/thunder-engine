extends Node

## Singleton that manages scene operations[br]
##
## Since the management of scenes in Godot is vague, it's recommended to use this
## singleton to implement scene management

## Emitted when the scene is reloaded
signal scene_reloaded

## Emitted when the scene is changed
signal scene_changed(to: Node)

## Emitted right before the new scene is loaded
signal pre_scene_changed

## Emitted when the current scene is ready
signal scene_ready

# Loaded scene buffer for optimization purpose
var _current_scene_buffer: PackedScene
## Current scene
var current_scene: Node
## Name of previous scene
var previous_scene_name: StringName
## Custom project-wise scenes, push them to this Dict in their own _ready method
var custom_scenes: Dictionary = {}


# Moves the current scene to viewport
func _ready() -> void:
	current_scene = get_tree().current_scene
	get_tree().root.remove_child.call_deferred(current_scene)
	GlobalViewport.vp.add_child.call_deferred(current_scene)


## Loads a node as current scene, call with call_deferred
func load_scene_deferred(scene: Node) -> void:
	if !scene: return
	previous_scene_name = current_scene.name
	current_scene.free()
	current_scene = scene
	GlobalViewport.vp.add_child(current_scene)
	scene_changed.emit()
	scene_ready.emit()


## Load a [PackedScene] and instantiate it as [Node], and then call [method load_scene] to make it current and shown
## Use with call_deferred
func load_scene_from_packed(pck: PackedScene) -> void:
	if !pck: return
	previous_scene_name = current_scene.name
	current_scene.free()
	var scene: Node = pck.instantiate()
	current_scene = scene
	GlobalViewport.vp.add_child(current_scene)
	scene_changed.emit(current_scene)
	scene_ready.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	if SettingsManager.settings.vsync == true:
		DisplayServer.window_set_vsync_mode.call_deferred(DisplayServer.VSYNC_ENABLED)


## Loads the scene from the given path and instantiates it
func goto_scene(path: String) -> void:
	#if DisplayServer.window_get_vsync_mode(0) == DisplayServer.VSYNC_ENABLED:
	#	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	pre_scene_changed.emit()
	if !_current_scene_buffer || _current_scene_buffer.resource_path != path:
		_current_scene_buffer = load(path)
	load_scene_from_packed.call_deferred(_current_scene_buffer)


## Reload current scene
func reload_current_scene() -> void:
	scene_reloaded.emit()
	pre_scene_changed.emit()
	goto_scene(current_scene.scene_file_path)
