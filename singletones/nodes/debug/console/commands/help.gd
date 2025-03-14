extends Command

static func register() -> Command:
	return new().set_name("help").set_description("Prints this list").set_not_cheat()

func execute(args:Array) -> Command.ExecuteResult:
	var cmd = Console.commands
	var message: String = "List of commands:\n"
	var msg_arr: PackedStringArray
	for c in cmd.keys():
		var _name: String = cmd[c].name
		if cmd[c].debug_only:
			_name = "[color=deep_pink]" + _name + "[/color]"
		msg_arr.append("\t- %s%s" % [ _name, cmd[c].get_help() ])
	
	message += "\n".join(msg_arr)
	return Command.ExecuteResult.new(message)
