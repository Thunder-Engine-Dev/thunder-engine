extends Command

static func register() -> Command:
	return new().set_name("setgamespeed").add_param("val", TYPE_INT).set_description("Sets game speed")

func execute(args:Array) -> Command.ExecuteResult:
	Engine.time_scale = args[0].to_float()
	
	var result: Command.ExecuteResult = Command.ExecuteResult.new("Game speed set to " + str(Engine.time_scale))
	return result

