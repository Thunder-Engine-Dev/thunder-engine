extends Command

static func register() -> Command:
	return new().set_name("settweak") \
	.add_param("tweak_name", TYPE_STRING, false) \
	.add_param("value", TYPE_STRING, true) \
	.set_debug().set_description("Sets a specified tweak to a specified value")

func execute(args:Array) -> Command.ExecuteResult:
	if len(args) < 2:
		return Command.ExecuteResult.new("Current Value: " + str(SettingsManager.get_tweak(args[0])))
	
	SettingsManager.set_tweak(args[0], str_to_var(args[1]))
	
	return Command.ExecuteResult.new("Success")
