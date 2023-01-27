extends Command

static func register() -> Command:
	return new().set_name("say").add_param("message", TYPE_STRING).set_description("Prints message in console")

func execute(args:Array) -> Command.ExecuteResult:
	var msg: String
	for w in args:
		msg += w + ' '
	
	var result: Command.ExecuteResult = Command.ExecuteResult.new(msg)
	return result

