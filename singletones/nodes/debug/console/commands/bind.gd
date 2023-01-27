extends Command

static func register() -> Command:
	return new().set_name("bind").add_param("keycode", TYPE_INT).add_param("command", TYPE_STRING).set_description("Binds a command to a preferred key")

func execute(args:Array) -> Command.ExecuteResult:
	var result: Command.ExecuteResult = Command.ExecuteResult.new(NIY)
	return result

