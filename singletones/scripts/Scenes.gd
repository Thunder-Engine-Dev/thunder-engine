extends Node

## Singleton that manages scene operations[br]
##
## Since the management of scenes in Godot is vague, it's recommended to use this
## singleton to implement scene management

## Emitted when the scene is changed
signal scene_changed(to: Node)

# Loaded scene buffer for optimization purpose
var _current_scene_buffer: PackedScene
## Current scene
var current_scene: Node

# Moves the current scene to viewport
func _ready() -> void:
	current_scene = get_tree().current_scene
	get_tree().root.remove_child.call_deferred(current_scene)
	GlobalViewport.vp.add_child.call_deferred(current_scene)

## Loads a node as current scene, call with call_deferred
func load_scene_deferred(scene: Node) -> void:
	if !scene: return
	current_scene.free()
	current_scene = scene
	GlobalViewport.vp.add_child(current_scene)
	scene_changed.emit()

## Load a [PackedScene] and instantiate it as [Node], and then call [method load_scene] to make it current and shown
## Use with call_deferred
func load_scene_from_packed(pck: PackedScene) -> void:
	if !pck: return
	current_scene.free()
	var scene: Node = pck.instantiate()
	current_scene = scene
	GlobalViewport.vp.add_child(current_scene)
	scene_changed.emit()

## Loads the scene from the given path and instantiates it
func goto_scene(path: String) -> void:
	if !_current_scene_buffer || _current_scene_buffer.resource_path != path:
		_current_scene_buffer = load(path)
	load_scene_from_packed.call_deferred(_current_scene_buffer)

## Reload current scene
func reload_current_scene() -> void:
	goto_scene(current_scene.scene_file_path)
