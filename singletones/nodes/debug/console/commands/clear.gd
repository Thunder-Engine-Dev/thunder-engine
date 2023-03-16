extends Command

static func register() -> Command:
	return new().set_name("clear").set_description("Clears console output")

func execute(args:Array) -> Command.ExecuteResult:
	Console.history = []
	Console.position_in_history = 0
	Console.output.text = ""
	return Command.ExecuteResult.new("")

