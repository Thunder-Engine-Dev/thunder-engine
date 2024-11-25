extends Command

static func register() -> Command:
	return new().set_name("setplayervar").add_param("var", TYPE_STRING).add_param("val", TYPE_OBJECT).set_debug().set_description("PLACEHOLDER")

func execute(args:Array) -> Command.ExecuteResult:
	var result: Command.ExecuteResult = Command.ExecuteResult.new(NIY)
	return result
