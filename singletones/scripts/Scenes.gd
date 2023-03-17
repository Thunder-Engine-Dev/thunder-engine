extends Node

## Singleton that manages scene operations[br]
## Because of vague implement of scenes in Godot, we need to have such a singleton to manage 
## each scene we need, and with this one, it's available to achieve them

## The scene that is displaying and running, instead of main scene when you run
## the whole project and defined a main scene and try referring [member SceneTree.current_scene]
var current_scene:Node
var _current_scene_path: String
var _current_scene_packed:PackedScene
var _current_root:Node

var _hung_scene:Node
var _hung_scene_process_mode:ProcessMode

## No-param-edition of [signal scene_changed]
signal scene_changed_notification

## Emitted when scene got changed or unhung-as-current
signal scene_changed(to: PackedScene)

## Emitted when calling [method hang_scene] or [method hang_current_scene]
signal scene_got_hung(hung: Node)


## Register the scene as [member current_scene], this is the preparation of
## [method install_scene]
func register(scene:Node) -> void:
	if current_scene == scene: return
	
	current_scene = scene
	if current_scene.is_inside_tree(): _current_root = scene.get_parent()
	
	if _current_scene_path != current_scene.scene_file_path:
		_current_scene_path = current_scene.scene_file_path
		_current_scene_packed = load(_current_scene_path)


## Install [member current_scene] that hasn't been added as the child of main scene,
## used to make [member current_scene] activated and display
func install_scene() -> void:
	if _current_root.is_ancestor_of(current_scene): return
	_current_root.add_child(current_scene)


## Load a scene [Node] as [member current_scene][br]
## [color=orange][b]Note:[/b][/color] The [code]scene[/code] is recommended to be the one NOT [member current_scene]
func load_scene(scene:Node) -> void:
	register(scene)
	install_scene()

## Load a [PackedScene] and instantiate it as [Node], and then call [method load_scene] to make it current and shown
func load_scene_from_packed(pck: PackedScene) -> void:
	if !pck: return
	var scene: Node = pck.instantiate()
	load_scene(scene)


## Unload current scene, making [member current_scene] [code]null[/code] and
## disappear from the screen[br]
## If [code]delete_current_packed[/code] is [code]true[/code], then remove the scene from memory
func unload_current_scene(delete_current_packed: bool = true) -> void:
	if delete_current_packed: _current_scene_packed = null
	current_scene.queue_free()
	scene_changed_notification.emit()


## Switch [member current_scene] to a scene [Node] given[br]
## If [code]hang_current[/code] is [code]true[/code], the previous current scene will be hung with [method hang_current_scene]
func switch_to_scene(to: Node, hang_current: bool = false) -> void:
	if hang_current: hang_current_scene()
	else: unload_current_scene()
	load_scene(to)
	
	scene_changed.emit(current_scene)
	scene_changed_notification.emit()

## Switch [member current_scene] to an instantiated [PackedScene] given[br]
## If [code]hang_current[/code] is [code]true[/code], the previous current scene will be hung with [method hang_current_scene]
func switch_to_scene_packed(pck: PackedScene, hang_current:bool = false) -> void:
	if hang_current: hang_current_scene()
	else: unload_current_scene()
	load_scene_from_packed(pck)
	
	scene_changed.emit(current_scene)
	scene_changed_notification.emit()


## Reload [member current_scene]
func reload_current_scene() -> void:
	unload_current_scene(false)
	load_scene_from_packed(_current_scene_packed)


## Hang a scene [Node] and make its [method Node._process] and [method Node._physics_process] paused
func hang_scene(scene: Node) -> void:
	if _hung_scene: return
	
	_hung_scene = scene
	
	_hung_scene_process_mode = scene.process_mode
	if &"visible" in scene: scene.visible = false
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	
	scene_got_hung.emit(scene)
	scene_changed_notification.emit()

## Equals to [code]hang_scene(current_scene)[/code]
func hang_current_scene() -> void:
	hang_scene(current_scene)

## Unhang the hung scene and make it as [member current_scene]
func unhang_scene_as_current() -> void:
	if !_hung_scene: return
	
	register(_hung_scene)
	
	if &"visible" in current_scene: current_scene.visible = true
	current_scene.process_mode = _hung_scene_process_mode
	
	_hung_scene = null
	_hung_scene_process_mode = ProcessMode.PROCESS_MODE_INHERIT
	
	scene_changed.emit(current_scene)
	scene_changed_notification.emit()

## Unhang the hung scene and call [method Node.queue_free] on it
func unhang_scene_and_queue_free() -> void:
	if !_hung_scene: return
	_hung_scene.queue_free()
	_hung_scene = null

## Swap hung scene and [member current_scene]
func swap_hung_scene_and_current_scene() -> void:
	if !_hung_scene || !current_scene: return
	
	var swapped: Node = current_scene
	unhang_scene_as_current()
	hang_scene(swapped)
