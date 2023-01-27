extends Command

static func register() -> Command:
	return new().set_name("unbind").add_param("keycode", TYPE_INT).set_description("Unbinds a command")

func execute(args:Array) -> Command.ExecuteResult:
	var result: Command.ExecuteResult = Command.ExecuteResult.new(NIY)
	return result

