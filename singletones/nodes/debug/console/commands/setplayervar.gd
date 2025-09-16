extends Command

var persist_vars: Dictionary = {}

static func register() -> Command:
	return new().set_name("setplayervar") \
	.add_param("property", TYPE_STRING, true) \
	.add_param("value", TYPE_FLOAT, true) \
	.add_param("persist?", TYPE_BOOL, true) \
	.set_description("Modifies Player Config. Without arguments, will dump a list of properties to modify. If the third argument is true, the command will automatically run on level restart.")


func execute(args:Array) -> Command.ExecuteResult:
	var result: Command.ExecuteResult = Command.ExecuteResult.new("Error: Player not found.")
	var pl := Thunder._current_player
	if !pl: return result
	if args.is_empty():
		var list: Array[Dictionary] = pl.suit.physics_config.get_property_list()
		var sorted: PackedStringArray
		for i in list:
			if i.usage & PROPERTY_USAGE_EDITOR && (i.type == TYPE_INT || i.type == TYPE_FLOAT):
				sorted.append(i.name)
		return Command.ExecuteResult.new("List of properties:\n[color=cyan]%s[/color]" % ["[/color]; [color=cyan]".join(sorted)])
	if len(args) == 1:
		var value = pl.suit.physics_config.get(args[0])
		if value:
			return Command.ExecuteResult.new("%s is %s" % [args[0], value])
		return Command.ExecuteResult.new("Error: Property not found.")
	if args[0] == "script": return Command.ExecuteResult.new(Error.Wrong)
	pl.suit.physics_config.set(args[0], args[1])
	if len(args) >= 3 && !args[2].is_empty():
		if ["no", "false", "0", "off", "disable", "remove"].has(args[2].to_lower()):
			persist_vars.erase(args[0])
			if persist_vars.is_empty():
				Thunder._disconnect(Scenes.scene_ready, patch_level)
			return Command.ExecuteResult.new("Success, persistence from this property removed")
		elif ["yes", "true", "1", "on", "enable", "add"]:
			if persist_vars.is_empty():
				Thunder._connect(Scenes.scene_ready, patch_level)
			persist_vars[args[0]] = args[1]
			return Command.ExecuteResult.new("Success, added persistence to this property")
	return Command.ExecuteResult.new("Success")

func patch_level() -> void:
	if !Scenes.is_inside_tree():
		return
	var pl: Player = Thunder._current_player
	if !pl:
		return
	for i in persist_vars.keys():
		pl.suit.physics_config.set(i, persist_vars[i])
