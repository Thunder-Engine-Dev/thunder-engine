extends Command

static func register() -> Command:
	return new().set_name("cv_infshoot").set_description("Removes a limit for shooting player projectiles.")

func execute(args:Array) -> Command.ExecuteResult:
	
	# "res://engine/objects/players/behaviors/player_projectile.gd"
	var _the_var = Console.cv.unlimited_player_projectiles
	Console.cv.unlimited_player_projectiles = !_the_var
	if !_the_var:
		return Command.ExecuteResult.new("Success, ON")
	return Command.ExecuteResult.new("Success, OFF")
