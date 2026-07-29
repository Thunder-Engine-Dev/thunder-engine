extends Command

static func register() -> Command:
	return new().set_name("help").add_param("command", TYPE_STRING, true) \
		.set_description("Get info about commands").set_not_cheat()

func execute(args: Array[String]) -> Command.ExecuteResult:
	var cmds = Console.commands
	var message: String = "List of commands:\n"
	var msg_arr: PackedStringArray
	if args.size() > 0:
		if !args[0] in cmds.keys():
			return Command.ExecuteResult.new("Command not found", Error.Param)
		message = "Command: [color=lime]" + args[0] + "[/color]"
		
		var cmd: Command = cmds[args[0]]
		
		msg_arr.append("\nDescription: %s" % [ cmd.description ])
		if cmd._get_usage():
			msg_arr.append("Usage: %s" % [ cmd._get_usage() ])
	
	if args.size() == 0:
		for c in cmds.keys():
			var _name: String = cmds[c].name
			if cmds[c].debug_only:
				_name = "[color=deep_pink]" + _name + "[/color]"
			elif cmds[c].is_cheat:
				_name = "[color=light_pink]" + _name + "[/color]"
			msg_arr.append("\t- %s%s" % [ _name, cmds[c].get_help() ])
	
	message += "\n".join(msg_arr)
	return Command.ExecuteResult.new(message)

func get_argument_options(args: PackedStringArray, index: int) -> Array:
	var result: Array
	if index == 0:
		return Console.commands.keys()
	return result
