extends Command

static func register() -> Command:
	return new().set_name("safepits").set_description("Bottomless pits act like springboards.")

func execute(args:Array) -> Command.ExecuteResult:
	
	# "res://engine/scripts/classes/level/level.gd"
	var _the_var = Console.cv.get("starman_pit_bounce", false)
	Console.cv.starman_pit_bounce = !_the_var
	if !_the_var:
		return Command.ExecuteResult.new("Success, ON")
	return Command.ExecuteResult.new("Success, OFF")
