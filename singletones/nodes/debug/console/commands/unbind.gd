extends Command

static func register() -> Command:
	return new().set_name("unbind").add_param("key", TYPE_STRING).set_description("Unbinds a command")

func execute(args:Array) -> Command.ExecuteResult:
	var result: Command.ExecuteResult = Command.ExecuteResult.new(NIY)
	return result

