extends Command

static func register() -> Command:
	return new().set_name("cv_shownames").set_description(
		"Show object's name & class under mouse cursor. Hold Shift/Ctrl/Alt for Areas/Tiles/Collisions; double press to toggle."
	)

func execute(args: Array) -> Command.ExecuteResult:
	
	Console.cv.object_names_shown = !Console.cv.object_names_shown
	if Console.cv.object_names_shown:
		if !GlobalViewport.has_node("DebugMouseLabel"):
			var mlabel = load("res://engine/singletones/nodes/viewport/debug_mouse_label.tscn").instantiate()
			GlobalViewport.add_child(mlabel, true)
		if !Scenes.scene_ready.is_connected(patch_level):
			Thunder._connect(Scenes.scene_ready, patch_level)
			patch_level()
	else:
		Thunder._disconnect(Scenes.scene_ready, patch_level)
	
	return Command.ExecuteResult.new("Success")


func patch_level() -> void:
	if !is_instance_valid(Scenes.current_scene):
		return
	if Scenes.current_scene.has_node("DebugDrawNode"):
		return
	var node_2d = Node2D.new()
	node_2d.name = "DebugDrawNode"
	node_2d.top_level = true
	node_2d.z_index = 100
	Scenes.current_scene.add_child(node_2d)
