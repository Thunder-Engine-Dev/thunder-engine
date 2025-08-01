extends Command

static func register() -> Command:
	return new().set_name("unpause").set_description("Unpauses the game.")

func execute(args:Array) -> Command.ExecuteResult:
	Thunder.set_pause_game(false)
	Thunder.get_tree().root.grab_focus()
	return Command.ExecuteResult.new("Success")
