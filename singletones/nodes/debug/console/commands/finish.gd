extends Command

static func register() -> Command:
	return new().set_name("finish").set_description("Finish the level")

func execute(args:Array) -> Command.ExecuteResult:
	var level = Scenes.current_scene
	if !level.has_method(&"finish"):
		return Command.ExecuteResult.new("ERROR: Invalid scene!")
	
	level.completion_music = null
	level.finish()
	return Command.ExecuteResult.new("Success")

