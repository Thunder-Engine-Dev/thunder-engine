extends Command

static func register() -> Command:
	return new().set_name("voice").add_param("ID", TYPE_STRING).set_description("Plays a voice line by current character")

func execute(args:Array) -> Command.ExecuteResult:
	var voice_line = CharacterManager.get_voice_line(args[0])
	if !voice_line:
		return Command.ExecuteResult.new("Voice Line Does Not Exist")
	if voice_line is Array:
		var temp_v = voice_line.pick_random()
		voice_line = temp_v
	Audio.play_1d_sound(voice_line)
	
	var result: Command.ExecuteResult = Command.ExecuteResult.new("Success")
	return result
