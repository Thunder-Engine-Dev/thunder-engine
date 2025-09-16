extends Command

static func register() -> Command:
	return new().set_name("clear").set_description("Clears console output") \
	.set_not_cheat()

func execute(args:Array) -> Command.ExecuteResult:
	Console.output.text = ""
	return Command.ExecuteResult.new("")
