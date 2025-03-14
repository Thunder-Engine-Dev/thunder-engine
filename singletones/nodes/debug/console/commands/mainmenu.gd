extends Command

var path = ProjectSettings.get("application/thunder_settings/main_menu_path")

static func register() -> Command:
	return new().set_name("mainmenu").set_description("Go to main menu") \
	.set_not_cheat()

func execute(args:Array) -> Command.ExecuteResult:
	Scenes.goto_scene(path)
	return Command.ExecuteResult.new("Success")
