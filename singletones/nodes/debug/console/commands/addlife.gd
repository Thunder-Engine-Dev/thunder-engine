extends Command

static func register() -> Command:
	return new().set_name("addlife").add_param("amount", TYPE_INT, true).set_description("Adds lives.")

func execute(args:Array) -> Command.ExecuteResult:
	if args.is_empty() || is_nan(float(args[0])):
		Thunder.add_lives(1)
	else:
		Data.add_lives(int(args[0]))
		if Thunder._current_player && is_instance_valid(Scenes.current_scene):
			ScoreTextLife.new("%sUP" % args[0], Thunder._current_player, Scenes.current_scene)
	return Command.ExecuteResult.new("Success")
	
