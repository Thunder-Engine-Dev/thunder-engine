extends MenuSelection

enum CREDITS_OPTION {
	JumpToScene,
	AddSceneAsChild
}
@export var credits_behavior: CREDITS_OPTION = CREDITS_OPTION.JumpToScene
var was_paused: bool

func _handle_select(mouse_input: bool = false) -> void:
	super(mouse_input)
	var cred_path = ProjectSettings.get_setting("application/thunder_settings/credits_path")
	match credits_behavior:
		CREDITS_OPTION.JumpToScene:
			SettingsManager.save_settings()
			Scenes.goto_scene(cred_path)
		CREDITS_OPTION.AddSceneAsChild:
			add_scene_to_child(cred_path)

func add_scene_to_child(cred_path) -> void:
	was_paused = get_tree().paused
	if !get_tree().paused:
		get_tree().paused = true
	for i in Audio._music_channels:
		if !is_instance_valid(Audio._music_channels[i]): continue
		if Audio._music_channels[i].process_mode == Node.PROCESS_MODE_ALWAYS:
			Audio._music_channels[i].process_mode = Node.PROCESS_MODE_DISABLED
	
	var credits_loaded = load(cred_path)
	assert(is_instance_valid(credits_loaded), "Credits path is invalid. Check Project Settings and set a correct path to the credits scene")
	
	var credits_scene: Node = credits_loaded.instantiate()
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	GlobalViewport.vp.add_child(canvas_layer)
	canvas_layer.layer = 127
	canvas_layer.add_child(credits_scene)
	_add_scene_tree_entered(credits_scene)
	credits_scene.tree_exited.connect(_add_scene_tree_exited.bind(canvas_layer))

func _add_scene_tree_entered(credits: Node) -> void:
	credits.process_mode = Node.PROCESS_MODE_ALWAYS

func _add_scene_tree_exited(canvas_layer: CanvasLayer) -> void:
	if !is_inside_tree(): return
	canvas_layer.queue_free()
	if !is_instance_valid(Scenes.current_scene): return
	if !was_paused:
		get_tree().paused = was_paused
	for i in Audio._music_channels:
		if !is_instance_valid(Audio._music_channels[i]): continue
		if Audio._music_channels[i].process_mode == Node.PROCESS_MODE_DISABLED:
			Audio._music_channels[i].process_mode = Node.PROCESS_MODE_ALWAYS
