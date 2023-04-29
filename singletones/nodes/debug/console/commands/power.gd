extends Command

static func register() -> Command:
	return new().set_name("power").add_param("state", TYPE_STRING).set_description("Set current player power state. Only built-in states for now")

func execute(args:Array) -> Command.ExecuteResult:
	var state = load("res://engine/objects/players/prefabs/prefabs/%s_state.tres" % args[0])
	if !state:
		return Command.ExecuteResult.new("Try one of these: beetroot, big, flower, lui, small")
	
	Thunder._current_player_state = state
	return Command.ExecuteResult.new("Success")

