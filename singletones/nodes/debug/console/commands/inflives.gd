extends Command

static func register() -> Command:
	return new().set_name("inflife").set_description("Infinite lives!")

func execute(args:Array) -> Command.ExecuteResult:
	if !Scenes.scene_ready.is_connected(patch_mario):
		Thunder._connect(Scenes.scene_ready, patch_mario)
		return Command.ExecuteResult.new("Success, Enabled")
	else:
		Thunder._disconnect(Scenes.scene_ready, patch_mario)
		if Data.values.lives < 0:
			Data.values.lives = 0
		return Command.ExecuteResult.new("Success, Disabled")
		

func patch_mario() -> void:
	if is_instance_valid(Thunder._current_player):
		Thunder._current_player.death_check_for_lives = false
