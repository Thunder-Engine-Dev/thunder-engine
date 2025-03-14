extends Command

static func register() -> Command:
	return new().set_name("bind") \
		.add_param("option", TYPE_STRING, true) \
		.add_param("key", TYPE_STRING, true) \
		.add_param("command", TYPE_STRING, true) \
		.set_description("Binds a command to a preferred key") \
		.set_not_cheat()

func execute(args: Array) -> Command.ExecuteResult:
	var option_list: String = "set, remove, list"
	if args.is_empty():
		return Command.ExecuteResult.new(option_list)

	var arg_option: String = args[0]
	
	if arg_option == "list":
		return Command.ExecuteResult.new(_get_bind_list())
	elif arg_option == "rawlist":
		return Command.ExecuteResult.new(_get_bind_raw_list())
		
	if !arg_option in ["set", "remove"]:
		return Command.ExecuteResult.new(option_list)
	
	if arg_option == "reset":
		if len(args) == 1:
			Console.bind_logic.binds = {}
			Console.bind_logic.reload_binds()
			return Command.ExecuteResult.new("Binds have been reset successfully")
		else:
			return Command.ExecuteResult.new("[color=red]Be careful with resetting ALL binds. Nothing happened[/color]")
	
	elif arg_option == "remove":
		if len(args) == 2 && args[1].is_valid_int():
			var ind := int(args[1])
			var rawlist: Dictionary = _get_bind_raw_list()
			var _bind = rawlist.get(ind)
			if !_bind:
				return Command.ExecuteResult.new("[color=red]Bind with such index does not exist[/color]")
			Console.bind_logic.binds["_bind_" + _bind.command].erase(_bind.key_combo)
			Console.bind_logic.reload_binds()
			Console.bind_logic.save_binds()
			return Command.ExecuteResult.new("Bind removed successfully")
		
		return Command.ExecuteResult.new("[color=red]Error[/color]: Type [color=yellow]bind list[/color] and choose an index of a bind you want to remove.")
	
	if len(args) < 3:
		return Command.ExecuteResult.new("\n".join([
			messages[Error.Param],
			"[color=red]Usage:[/color] %s%s" % [name, _get_usage()]
		]))
	
	var arg_key: String = args[1]
	
	var keycodes := []
	for i in arg_key.split("+"):
		i = i.replacen("_", " ")
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
			
		"remove":
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


func _get_bind_raw_list() -> Dictionary:
	var list: Dictionary = Console.bind_logic.binds
	var binds: Dictionary = {}
	var index: int = 0
	var i: int = 0
	for arrays in list.values():
		for key_combo in arrays:
			index += 1
			var command: String = list.keys()[i].split("_bind_")[1]
			binds[index] = {
				"key_combo" = key_combo,
				"command" = command,
			}
		i += 1
	
	return binds
