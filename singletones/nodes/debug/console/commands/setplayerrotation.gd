extends Command

static func register() -> Command:
	return new().set_name("setplayerrotation").add_param("value", TYPE_FLOAT) \
		.set_description("Set player rotation, in degrees. Upside-down rotation might visually look like controls are inverted. Set to 0 for default rotation")

func execute(args: Array) -> Command.ExecuteResult:
	var pl: Player = Thunder._current_player
	if !pl:
		return Command.ExecuteResult.new("ERROR: Player not found")
	
	pl.rotation_degrees = float(args[0])
		
	return Command.ExecuteResult.new("Success")
