extends Command

static func register() -> Command:
	return new().set_name("savetweaks").set_description("Saves current tweaks.")

func execute(args:Array) -> Command.ExecuteResult:
	SettingsManager.save_tweaks()
	return Command.ExecuteResult.new("Success")
