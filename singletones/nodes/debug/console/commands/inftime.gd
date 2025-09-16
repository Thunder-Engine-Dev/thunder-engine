extends Command

static func register() -> Command:
	return new().set_name("inftime").set_description("Infinite timer!")

func execute(args:Array) -> Command.ExecuteResult:
	if !Scenes.scene_ready.is_connected(patch_mario):
		Thunder._connect(Scenes.scene_ready, patch_mario)
		if is_instance_valid(Thunder._current_hud):
			Thunder._disconnect(Thunder._current_hud.timer.timeout, Thunder._current_hud._on_timer_timeout)
		return Command.ExecuteResult.new("Success, Enabled")
	else:
		Thunder._disconnect(Scenes.scene_ready, patch_mario)
		if is_instance_valid(Thunder._current_hud):
			Thunder._connect(Thunder._current_hud.timer.timeout, Thunder._current_hud._on_timer_timeout)
		return Command.ExecuteResult.new("Success, Disabled (Restart the level to take effect)")
		

func patch_mario() -> void:
	Data.values.time = -1
