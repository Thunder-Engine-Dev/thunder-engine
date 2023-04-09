extends Node

## Singleton that manages scene operations[br]
##
## Since the management of scenes in Godot is vague, it's recommended to use this
## singleton to implement scene management

## Emitted when the scene is changed
signal scene_changed(to: Node)


## Loads a node as current scene
func load_scene(scene: Node) -> void:
	if !scene: return
	get_tree().current_scene = scene


## Load a [PackedScene] and instantiate it as [Node], and then call [method load_scene] to make it current and shown
func load_scene_from_packed(pck: PackedScene) -> void:
	if !pck: return
	var scene: Node = pck.instantiate()
	load_scene(scene)


## Unload current scene
func unload_current_scene() -> void:
	get_tree().unload_current_scene()


## Reload current scene
func reload_current_scene() -> void:
	get_tree().reload_current_scene()
