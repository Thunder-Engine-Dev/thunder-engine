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

## Emitted when loading the scene failed
signal scene_change_failed

const LOADING_SCREEN = preload("res://engine/components/loading_screen/loading_screen.tscn")

# Loaded scene buffer for optimization purpose
var _current_scene_buffer: PackedScene
## Current scene
var current_scene: Node
## Name of previous scene
var previous_scene_name: StringName
## Resource path to the previous scene
var previous_scene_path: StringName
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
	previous_scene_path = current_scene.scene_file_path
	current_scene.free()
	current_scene = scene
	GlobalViewport.vp.add_child(current_scene)
	scene_changed.emit(current_scene)
	if Thunder.autosplitter.get_conf("pause_on_loading"):
		Thunder.autosplitter.unpause_igt()
	scene_ready.emit()


## Load a [PackedScene] and instantiate it as [Node], and then call [method load_scene] to make it current and shown
## Use with call_deferred
func load_scene_from_packed(pck: PackedScene) -> void:
	if !pck: return
	if !pck.can_instantiate():
		scene_change_failed.emit()
		return
	previous_scene_name = current_scene.name
	previous_scene_path = current_scene.scene_file_path
	current_scene.free()
	var scene: Node = pck.instantiate()
	
	current_scene = scene
	GlobalViewport.vp.add_child(current_scene)
	scene_changed.emit(current_scene)
	if Thunder.autosplitter.get_conf("pause_on_loading"):
		Thunder.autosplitter.unpause_igt()
	scene_ready.emit()
	get_tree().paused = false


## Loads the scene from the given path and instantiates it
func goto_scene(path: String) -> void:
	pre_scene_changed.emit()
	if Thunder.autosplitter.get_conf("pause_on_loading"):
		Thunder.autosplitter.pause_igt()
	if !_current_scene_buffer || _current_scene_buffer.resource_path != path:
		_current_scene_buffer = load(path)
	load_scene_from_packed.call_deferred(_current_scene_buffer)


func goto_scene_with_loading(path: String) -> void:
	if _current_scene_buffer && _current_scene_buffer.resource_path == path:
		reload_current_scene()
		return
	pre_scene_changed.emit()
	if Thunder.autosplitter.get_conf("pause_on_loading"):
		Thunder.autosplitter.pause_igt()
	var loading: Control = LOADING_SCREEN.instantiate()
	loading.scene = path
	load_scene_deferred.call_deferred(loading)


## Reload current scene
func reload_current_scene() -> void:
	scene_reloaded.emit()
	pre_scene_changed.emit()
	goto_scene(current_scene.scene_file_path)


func get_scene_path(scene_path_or_uid: String) -> String:
	if ResourceUID.has_id(ResourceUID.text_to_id(scene_path_or_uid)):
		return ResourceUID.get_id_path(ResourceUID.text_to_id(scene_path_or_uid))
	return scene_path_or_uid
