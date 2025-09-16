extends Command

static func register() -> Command:
	return new().set_name("cv_platcol").set_description("Display debug platform collisions.")

func execute(args:Array) -> Command.ExecuteResult:
	
	# res://engine/objects/platform/platform_block.gd
	Console.cv.platform_collision_shown = !Console.cv.platform_collision_shown
	return Command.ExecuteResult.new("Success")
