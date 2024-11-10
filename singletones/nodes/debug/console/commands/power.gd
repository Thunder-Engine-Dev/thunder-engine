extends Command

static func register() -> Command:
	return new().set_name("power").add_param("state", TYPE_STRING).set_description("Set current player power state")

func execute(args:Array) -> Command.ExecuteResult:
	var player: Player = Thunder._current_player
	if !player:
		return Command.ExecuteResult.new("Error: Player not found")
	var suit = CharacterManager.get_suit(args[0])
	if !suit:
		return Command.ExecuteResult.new("Try one of these: %s" % [CharacterManager.get_suit_names()])
	
	player.change_suit(suit)
	Thunder._current_player.suit = suit
	return Command.ExecuteResult.new("Success")
