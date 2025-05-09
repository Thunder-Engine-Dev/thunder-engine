extends Command

var path = ProjectSettings.get("application/thunder_settings/save_game_room_path")

static func register() -> Command:
	return new().set_name("saveroom").set_description("Go to save room. May break with transitions")

func execute(args:Array) -> Command.ExecuteResult:
	Scenes.goto_scene(path)
	return Command.ExecuteResult.new("Success")
