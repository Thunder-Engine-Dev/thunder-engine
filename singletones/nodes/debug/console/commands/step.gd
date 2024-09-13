extends Command

static func register() -> Command:
	return new().set_name("step").set_description("Unpause game process by 1 tick, then pause.")

func execute(args:Array) -> Command.ExecuteResult:
	
	Thunder.set_pause_game(false)
	Thunder._connect(Console.get_tree().physics_frame, Thunder.set_pause_game.bind(true), CONNECT_ONE_SHOT)
	return Command.ExecuteResult.new("Success")
