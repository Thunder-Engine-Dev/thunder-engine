extends Command

static func register() -> Command:
	return new().set_name("setplayerspeed").add_param("val", TYPE_INT).set_description("Sets player speed")

func execute(args:Array) -> Command.ExecuteResult:
	Thunder._current_player.config.max_run_speed = args[0].to_int()
	
	var result: Command.ExecuteResult = Command.ExecuteResult.new("Player run speed set to " + args[0])
	return result

