extends Command

static func register() -> Command:
	return new().set_name("bind").add_param("key", TYPE_STRING).add_param("command", TYPE_STRING).set_description("Binds a command to a preferred key")

func execute(args:Array) -> Command.ExecuteResult:
	#var key = OS.find_keycode_from_string(args[0])
	var result: Command.ExecuteResult = Command.ExecuteResult.new(NIY)
	return result

