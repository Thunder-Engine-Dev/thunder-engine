extends Command

var path = ProjectSettings.get("application/thunder_settings/save_game_room_path")

static func register() -> Command:
	return new().set_name("saveroom").set_description("Go to save room") \
	.set_not_cheat()

func execute(args:Array) -> Command.ExecuteResult:
	Scenes.goto_scene(path)
	return Command.ExecuteResult.new("Success")
