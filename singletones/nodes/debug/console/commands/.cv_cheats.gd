extends Command

static func register() -> Command:
	return null
	#return new().set_name("cv_cheats").add_param("value", TYPE_INT).set_not_cheat() \
	#.set_description("Set to 1 to allow cheat commands. THIS WILL BLOCK ACHIEVEMENTS FOR THE CURRENT SESSION; RESTART THE GAME TO UNBLOCK.")

#func execute(args:Array) -> Command.ExecuteResult:
	#var has_enabled: bool
	#if args[0] is int && args[0] > 0:
		#has_enabled = true
	#elif args[0] is String && args[0].to_lower() == "true":
		#has_enabled = true
	#var old_var = Console.cv.allow_cheats
	#Console.cv.allow_cheats = has_enabled
	#if old_var == Console.cv.allow_cheats:
		#return Command.ExecuteResult.new("Error: Nothing changed.")
	#
	#if Console.cv.allow_cheats && OS.has_feature("template"):
		#Console.command_executed = true
	#return Command.ExecuteResult.new("Success, " + ("ON" if has_enabled else "OFF"))
