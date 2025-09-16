extends Command

static func register() -> Command:
	return new().set_name("cv_stats").set_description("Display debug info about player.")

func execute(args:Array) -> Command.ExecuteResult:
	
	# res://engine/singletones/nodes/debug/console/debug_player_stats.gd
	Console.cv.general_stats_shown = false
	Console.cv.player_stats_shown = !Console.cv.player_stats_shown
	if Console.cv.player_stats_shown:
		Thunder.set_pause_game(false)
		Thunder.get_tree().root.grab_focus()
	return Command.ExecuteResult.new("Success")
