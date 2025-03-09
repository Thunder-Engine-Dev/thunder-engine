extends Command

static func register() -> Command:
	return new().set_name("setplayerspeed").add_param("val", TYPE_FLOAT).set_description("Sets player speed")

func execute(args:Array) -> Command.ExecuteResult:
	if !Thunder._current_player.suit:
		return Command.ExecuteResult.new("No player suit is set!")
	
	Thunder._current_player.suit.physics_config.walk_max_running_speed = args[0].to_float()
	
	var result: Command.ExecuteResult = Command.ExecuteResult.new("Player run speed set to " + args[0])
	return result
