extends Command

static func register() -> Command:
	return new().set_name("goto").add_param("scene_path", TYPE_STRING).set_debug().set_description("Changes current scene to a specified scene.")

func execute(args:Array) -> Command.ExecuteResult:
	var scene = " ".join(args)
	var packed_scene: PackedScene = load(scene)
	if packed_scene && packed_scene.can_instantiate():
		Scenes.pre_scene_changed.emit()
		Scenes.load_scene_from_packed.call_deferred(packed_scene)
		return Command.ExecuteResult.new("Success")

	return Command.ExecuteResult.new("[color=red]Invalid Scene[/color]")
