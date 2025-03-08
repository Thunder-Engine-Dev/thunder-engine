extends Command

static func register() -> Command:
	return new().set_name("cv_forcesave").set_description("Toggle progress saving with console.")

func execute(args:Array) -> Command.ExecuteResult:
	
	# res://engine/singletones/scripts/ProfileManager.gd
	var _the_var = Console.cv.can_save_with_console
	Console.cv.can_save_with_console = !_the_var
	if _the_var:
		return Command.ExecuteResult.new("Success, ON")
	return Command.ExecuteResult.new("Success, OFF")
