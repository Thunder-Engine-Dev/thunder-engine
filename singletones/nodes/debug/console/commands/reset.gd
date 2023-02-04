extends Command

static func register() -> Command:
	return new().set_name("reset").set_description("Restart the scene")

func execute(args:Array) -> Command.ExecuteResult:
	Thunder._current_stage.restart()
	
	var result: Command.ExecuteResult = Command.ExecuteResult.new("Scene has been restarted")
	Console.hide()
	Console.get_tree().paused = false
	return result

