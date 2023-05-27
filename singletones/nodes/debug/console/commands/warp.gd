extends Command

static func register() -> Command:
	return new().set_name("warp").add_param("x", TYPE_FLOAT).add_param("y", TYPE_FLOAT).set_description("Warp the player to a certain place")

func execute(args:Array) -> Command.ExecuteResult:
	var player: Player = Thunder._current_player
	if !player:
		return Command.ExecuteResult.new("ERROR: No player is available!")
	
	player.global_position = Vector2(float(args[0]), float(args[1]))
	return Command.ExecuteResult.new("Success")

