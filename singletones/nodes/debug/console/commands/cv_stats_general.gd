extends Command

static func register() -> Command:
	return new().set_name("cv_stats_general").set_description("Display additional debug info.") \
	.add_param("set_pause", TYPE_BOOL, true)

func execute(args:Array) -> Command.ExecuteResult:
	
	# res://engine/singletones/nodes/debug/console/debug_player_stats.gd
	Console.cv.player_stats_shown = false
	Console.cv.general_stats_shown = !Console.cv.general_stats_shown
	if (args.is_empty() || !args.front()) && Console.cv.general_stats_shown:
		Thunder.set_pause_game(false)
		Thunder.get_tree().root.grab_focus()
	return Command.ExecuteResult.new("Success")
