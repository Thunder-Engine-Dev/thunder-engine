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

var LOADING_SCREEN = load("res://engine/components/loading_screen/loading_screen.tscn")

# Loaded scene buffer for optimization purpose
var _current_scene_buffer: PackedScene
var _pending_scenes: Array
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
	call_deferred(&"emit_signal", "scene_ready")


## Loads a node as current scene, call with call_deferred
func load_scene_deferred(scene: Node) -> void:
	if !scene: return
	previous_scene_name = current_scene.name
	previous_scene_path = current_scene.scene_file_path
	current_scene.free()
	current_scene = scene
	GlobalViewport.vp.add_child(current_scene)
	_pending_scenes = []
	scene_changed.emit(current_scene)
	if Thunder.autosplitter.get_conf("pause_on_loading"):
		Thunder.autosplitter.unpause_igt()
	Thunder.autosplitter.il_internal = 0
	Thunder.autosplitter.update_il_counter()
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
	_pending_scenes = []
	scene_changed.emit(current_scene)
	if Thunder.autosplitter.get_conf("pause_on_loading"):
		Thunder.autosplitter.unpause_igt()
	Thunder.autosplitter.il_internal = 0
	Thunder.autosplitter.update_il_counter()
	scene_ready.emit()
	get_tree().paused = false


## Loads the scene from the given path and instantiates it
func goto_scene(path: String) -> void:
	if !_pending_scenes.is_empty():
		push_error("Trying to load a scene while another one is loading. Aborting")
		return
	pre_scene_changed.emit()
	if Thunder.autosplitter.get_conf("pause_on_loading"):
		Thunder.autosplitter.pause_igt()
	if !_current_scene_buffer || _current_scene_buffer.resource_path != path:
		_current_scene_buffer = load(path)
	_pending_scenes.append(_current_scene_buffer)
	load_scene_from_packed.call_deferred(_current_scene_buffer)


## Loads [param path] with a screen transition.[br]
## [br]
## [param transition] may be:[br]
## - [code]&"auto"[/code] (default): circle or crossfade from the settings tweak[br]
## - a built-in / registered id ([code]&"circle"[/code], [code]&"crossfade"[/code],
##   [code]&"fade"[/code], [code]&"blur"[/code], …)[br]
## - a pre-configured [Transition] from [method TransitionManager.create_transition][br]
## - a [Callable] that configures the transition when auto resolves to circle
##   (or another non-[member Transition.switches_scene] type):[br]
##   [code]await Scenes.goto_scene_with_transition(path, func(t): t.with_speeds(0.04, -0.1).with_pause())[/code][br]
## [br]
## [param configure] is an optional [Callable] applied the same way when
## [param transition] is an id or instance (ignored for crossfade / [member Transition.switches_scene]).[br]
## [br]
## Crossfade-style transitions receive [param path] automatically via [method with_scene].
## Other transitions await [signal TransitionManager.transition_middle], then call [method goto_scene].
func goto_scene_with_transition(path: String, transition: Variant = &"auto", configure: Callable = Callable()) -> Transition:
	if is_instance_valid(TransitionManager.current_transition):
		TransitionManager.current_transition.queue_free()
		TransitionManager.current_transition = null
	
	var trans: Transition = TransitionManager._resolve_transition(transition, configure)
	
	if trans.switches_scene:
		if trans.has_method(&"with_scene"):
			trans.with_scene(path)
		TransitionManager.accept_transition(trans)
		return trans
	
	TransitionManager.accept_transition(trans)
	await TransitionManager.transition_middle
	goto_scene(path)
	return trans


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
