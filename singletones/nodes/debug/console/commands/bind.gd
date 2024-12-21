extends Command

static func register() -> Command:
	return new().set_name("bind") \
		.add_param("option", TYPE_STRING, true) \
		.add_param("key", TYPE_STRING, true) \
		.add_param("command", TYPE_STRING, true) \
		.set_description("Binds a command to a preferred key. Bind Remove does NOT work with old binds!")

func execute(args: Array) -> Command.ExecuteResult:
	var option_list: String = "set, remove, reset, list"
	if args.is_empty():
		return Command.ExecuteResult.new(option_list)

	var arg_option: String = args[0]
	
	if arg_option == "list":
		return Command.ExecuteResult.new(_get_bind_list())
		
	if !arg_option in ["set", "remove", "reset"]:
		return Command.ExecuteResult.new(option_list)
	
	if arg_option == "reset":
		if len(args) == 1:
			Console.bind_logic.binds = {}
			Console.bind_logic.reload_binds()
			return Command.ExecuteResult.new("Binds have been reset successfully")
		else:
			return Command.ExecuteResult.new("Be careful with resetting ALL binds. Nothing happened")
	
	if len(args) < 3:
		return Command.ExecuteResult.new("[color=red]Invalid Parameters[/color]")
	
	var arg_key: String = args[1]
	
	var keycodes := []
	for i in arg_key.split("+"):
		var key = OS.find_keycode_from_string(i)
		if !key:
			return Command.ExecuteResult.new("[color=red]Invalid Key[/color]")
		keycodes.append(key)
	
	var arg_command: String = " ".join(args).trim_prefix("%s %s " % [ args[0], args[1] ])
	
	if arg_option != "reset" && !Console.commands.has(arg_command.split(" ")[0]):
		return Command.ExecuteResult.new("[color=red]Invalid Command Name[/color]")

	
	match arg_option:
		"set":
			if !"_bind_" + arg_command in Console.bind_logic.binds:
				Console.bind_logic.binds["_bind_" + arg_command] = []
			if keycodes in Console.bind_logic.binds["_bind_" + arg_command]:
				return Command.ExecuteResult.new("[color=red]Bind already exists[/color]")
			Console.bind_logic.binds["_bind_" + arg_command].append(keycodes)
			Console.bind_logic.reload_binds()
			Console.bind_logic.save_binds()
			
			return Command.ExecuteResult.new("Bind set successfully")
			
		"remove": # TODO: this is Broken for some reason.
			print(Console.bind_logic.binds.keys())
			print(Console.bind_logic.binds["_bind_" + arg_command])
			print(keycodes)
			#if (
			#	!"_bind_" + arg_command in Console.bind_logic.binds ||
			#	!keycodes in Console.bind_logic.binds["_bind_" + arg_command]
			#):
			#	return Command.ExecuteResult.new("[color=red]Unable to remove bind[/color]")
			Console.bind_logic.binds["_bind_" + arg_command].erase(keycodes)
			if len(Console.bind_logic.binds["_bind_" + arg_command]) == 0:
				Console.bind_logic.binds.erase("_bind_" + arg_command)
			Console.bind_logic.reload_binds()
			Console.bind_logic.save_binds()
			return Command.ExecuteResult.new("Bind removed successfully")
	
	return Command.ExecuteResult.new(option_list)


func _get_bind_list() -> String:
	var list: Dictionary = Console.bind_logic.binds
	var binds: Array = ["List of binds:"]
	var index: int = 0
	var i: int = 0
	for arrays in list.values():
		for key_combo in arrays:
			index += 1
			var command: String = list.keys()[i].split("_bind_")[1]
			var combined_key: String = ""
			var j: int = 0
			for key in key_combo:
				if j == 1: combined_key += "+"
				combined_key += "[color=deep_pink]%s[/color]" % OS.get_keycode_string(key)
				j += 1
			binds.append("[%s] %s: %s" % [ index, combined_key, command ])
		i += 1
	
	return "
".join(binds)
