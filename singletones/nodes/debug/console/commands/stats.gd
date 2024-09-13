extends Command

static func register() -> Command:
	return new().set_name("stats").set_description("Display debug info about player.")

func execute(args:Array) -> Command.ExecuteResult:
	
	# res://engine/singletones/nodes/debug/console/debug_player_stats.gd
	Console.player_stats_shown = !Console.player_stats_shown
	if Console.player_stats_shown:
		Thunder.set_pause_game(false)
	return Command.ExecuteResult.new("Success")
