extends Command

static func register() -> Command:
	return new().set_name("setgravity").add_param("value", TYPE_FLOAT) \
		.set_description("Set global gravity of all bodies. Set to 0 for default gravity")

func execute(args: Array) -> Command.ExecuteResult:
	PhysicsServer2D.area_set_param(
		GlobalViewport.vp.find_world_2d().space,
		PhysicsServer2D.AREA_PARAM_GRAVITY, float(args[0])
	)
	return Command.ExecuteResult.new("Success")
