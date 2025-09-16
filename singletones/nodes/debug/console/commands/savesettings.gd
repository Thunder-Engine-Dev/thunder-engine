extends Command

static func register() -> Command:
	return new().set_name("savesettings").set_description("Saves current settings.")

func execute(args:Array) -> Command.ExecuteResult:
	SettingsManager.save_settings()
	return Command.ExecuteResult.new("Success")
