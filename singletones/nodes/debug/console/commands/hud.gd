extends Command

static func register() -> Command:
	return new().set_name("hud").set_description("Hide or show Heads-Up Display, if available.")

func execute(args:Array) -> Command.ExecuteResult:
	# res://engine/components/hud/hud.gd
	return Command.ExecuteResult.new("Success")
