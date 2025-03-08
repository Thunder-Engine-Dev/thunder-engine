extends Command

static func register() -> Command:
	return new().set_name("setplayervar").add_param("var", TYPE_STRING).add_param("val", TYPE_OBJECT).set_debug().set_description("PLACEHOLDER")

func execute(args:Array) -> Command.ExecuteResult:
	var result: Command.ExecuteResult = Command.ExecuteResult.new(NIY)
	var pl := Thunder._current_player
	if !pl: return result
	pl.set(args[0], args[1])
	return result
