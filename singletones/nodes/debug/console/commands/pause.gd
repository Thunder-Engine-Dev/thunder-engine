extends Command

static func register() -> Command:
	return new().set_name("pause").set_description("Pauses the game.")

func execute(args:Array) -> Command.ExecuteResult:
	Thunder.set_pause_game(true)
	return Command.ExecuteResult.new("Success")
