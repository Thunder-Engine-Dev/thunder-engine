extends Command

static func register() -> Command:
	return new().set_name("voice").add_param("ID", TYPE_STRING, true) \
	.set_description("Plays a global sound effect of the current character or skin") \
	.set_not_cheat()

func execute(args:Array) -> Command.ExecuteResult:
	var names: PackedStringArray = CharacterManager.voice_lines[CharacterManager.get_character_name()].keys()
	if len(args) == 0 || args[0].is_empty():
		return Command.ExecuteResult.new(
			"List of sounds: [color=cyan]%s[/color]"% ["[/color]; [color=cyan]".join(names)]
		)
	var voice_line = CharacterManager.get_sound_replace(null, null, args[0], false)
	if !voice_line:
		return Command.ExecuteResult.new("Error: A global sound effect with this name does not exist or was not modified by skin/character.")

	Audio.play_1d_sound(voice_line, true, { ignore_pause = true })
	
	var result: Command.ExecuteResult = Command.ExecuteResult.new("Success")
	return result
