extends Node

var current_scene:Node
var current_scene_packed:PackedScene
var current_root:Node

var hung_scene:Node
var hung_scene_process_mode:ProcessMode

signal scene_changed(to:PackedScene)
signal scene_got_hung(hung:Node)


# Register scene
func register(scene:Node) -> void:
	current_scene = scene
	if current_scene.is_inside_tree(): current_root = scene.get_parent()
	
	current_scene_packed = PackedScene.new()
	current_scene_packed.pack(current_scene)


# Install scene
func install_scene() -> void:
	if current_root.is_ancestor_of(current_scene): return
	current_root.add_child(current_scene)


# Load scene as current
func load_scene(scene:Node) -> void:
	register(scene)
	install_scene()

func load_scene_from_packed(pck:PackedScene) -> void:
	if !pck: return
	var scene:Node = pck.instantiate()
	load_scene(scene)


# Unload scene
func unload_current_scene(delete_current_packed:bool = true) -> void:
	if delete_current_packed: current_scene_packed = null
	current_scene.queue_free()
	Thunder.stage_changed.emit()


# Switch to scene
func switch_to_scene(to:Node,hang_current:bool = false) -> void:
	if hang_current: hang_current_scene()
	else: unload_current_scene()
	load_scene(to)
	scene_changed.emit(current_scene)

func switch_to_scene_packed(pck:PackedScene,hang_current:bool = false) -> void:
	if hang_current: hang_current_scene()
	else: unload_current_scene()
	load_scene_from_packed(pck)
	scene_changed.emit(current_scene)


# Reload current scene
func reload_current_scene() -> void:
	unload_current_scene(false)
	load_scene_from_packed(current_scene_packed)


# Hang scene
func hang_scene(scene:Node) -> void:
	if hung_scene: return
	
	hung_scene = scene
	scene_got_hung.emit(scene)
	
	hung_scene_process_mode = scene.process_mode
	if &"visible" in scene: scene.visible = false
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	
	Thunder.stage_changed.emit()

func hang_current_scene() -> void:
	hang_scene(current_scene)

# Unhang scene
func unhang_scene_as_current() -> void:
	if !hung_scene: return
	
	register(hung_scene)
	scene_changed.emit(current_scene)
	
	if &"visible" in current_scene: current_scene.visible = true
	current_scene.process_mode = hung_scene_process_mode
	
	hung_scene = null
	hung_scene_process_mode = ProcessMode.PROCESS_MODE_INHERIT
	
	Thunder.stage_changed.emit()

func unhang_scene_and_queue_free() -> void:
	if !hung_scene: return
	hung_scene.queue_free()
	hung_scene = null

# Swap hung scene and current scene
func swap_hung_scene_and_current_scene() -> void:
	if !hung_scene || !current_scene: return
	
	var swamped:Node = current_scene
	unhang_scene_as_current()
	hang_scene(swamped)
