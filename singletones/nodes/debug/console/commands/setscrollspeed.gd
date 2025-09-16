extends Command

static func register() -> Command:
	return new().set_name("setscrollspeed").add_param("speed", TYPE_FLOAT).set_description("Sets the autoscroll speed.")

func execute(args:Array) -> Command.ExecuteResult:
	var cam = GlobalViewport.vp.get_camera_2d()
	if !cam || !cam is PlayerCamera2D:
		return Command.ExecuteResult.new("[color=red]Current Scene has Invalid Camera[/color]")
	
	if cam.par is PathFollow2D && "speed" in cam.par:
		cam.par.speed = args[0]
		return Command.ExecuteResult.new("Success")

	return Command.ExecuteResult.new("[color=red]This command only works with Autoscroll Camera.[/color]")
