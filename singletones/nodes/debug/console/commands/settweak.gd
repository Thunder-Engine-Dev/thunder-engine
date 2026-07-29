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


func get_argument_options(args: PackedStringArray, index: int) -> Array:
	var result: Array
	if index == 0:
		result = ProjectSettings.get_property_list().map(
			func(prop):
				return prop.name
		).filter(
			func(prop):
				return "application/thunder_settings/tweaks" in prop && ProjectSettings.has_setting(prop)
		).map(
			func(prop: String):
				return prop.trim_prefix("application/thunder_settings/tweaks/")
		)
		result.sort()
		
	elif index == 1:
		result = ["true", "false"]
	return result
