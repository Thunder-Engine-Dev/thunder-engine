extends Command

static func register() -> Command:
	return new().set_name("character").add_param("name", TYPE_STRING).set_description("Set current character. Does not save automatically")

func execute(args:Array) -> Command.ExecuteResult:
	var chars = CharacterManager.get_character_names()
	if !args[0] in chars:
		return Command.ExecuteResult.new("Try one of these: %s" % [chars])
	
	SettingsManager.settings.character = args[0]
	var pl = Thunder._current_player
	if pl && pl is Player:
		pl.change_suit(CharacterManager.get_suit(Thunder._current_player_state.name), false, true)
	return Command.ExecuteResult.new("Success")
