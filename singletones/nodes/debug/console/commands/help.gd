extends Command

static func register() -> Command:
	return new().set_name("help").set_description("Prints this list")

func execute(args:Array) -> Command.ExecuteResult:
	var cmd = Console.commands
	var message: String = "List of commands:\n"
	for c in cmd.keys():
		message += "\t- %s%s\n" % [cmd[c].name,cmd[c].get_help()]
	return Command.ExecuteResult.new(message)

