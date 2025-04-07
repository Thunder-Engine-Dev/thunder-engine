extends Command

static func register() -> Command:
	return new().set_name("hide").set_description("Hides the console").set_not_cheat()

func execute(args:Array) -> Command.ExecuteResult:
	var result: Command.ExecuteResult = Command.ExecuteResult.new("Hid the console")
	Console.hide()
	return result
