extends Command

static func register() -> Command:
	return new().set_name("kill").set_description("Kill the player")

func execute(args:Array) -> Command.ExecuteResult:
	var player: Player = Thunder._current_player
	if !player:
		return Command.ExecuteResult.new("ERROR: No player is available!")
	
	player.die()
	return Command.ExecuteResult.new("Success")
