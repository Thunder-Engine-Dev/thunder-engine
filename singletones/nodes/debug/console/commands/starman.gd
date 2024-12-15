extends Command

static func register() -> Command:
	return new().set_name("starman").set_description("Give starman invincibility")

func execute(args:Array) -> Command.ExecuteResult:
	var player: Player = Thunder._current_player
	if !player:
		return Command.ExecuteResult.new("ERROR: No player is available!")
	
	var starman_duration = 10.0
	if !args.is_empty() && float(args[0]):
		starman_duration = float(args[0])
	player.starman(starman_duration)
	#var mus_loader = Scenes.current_scene.get_node_or_null("MusicLoader")
	#if !mus_loader: return
	#mus_loader.play_immediately = false
	#mus_loader.pause_music()
	#for i in Audio._music_tweens:
		#i.kill()
	#if Audio._music_channels.has(98) && is_instance_valid(Audio._music_channels[98]):
		#Audio._music_channels[98].volume_db = 0
	#else:
		#Audio.play_music(starman_music, 98, { volume = 0 })
	player._starman_faded = false
	return Command.ExecuteResult.new("Success")
