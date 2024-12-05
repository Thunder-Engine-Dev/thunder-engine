extends Command

static func register() -> Command:
	return new().set_name("inftime").set_description("Infinite timer!")

func execute(args:Array) -> Command.ExecuteResult:
	if !Scenes.scene_ready.is_connected(patch_mario):
		Thunder._connect(Scenes.scene_ready, patch_mario)
		return Command.ExecuteResult.new("Success, Enabled")
	else:
		Thunder._disconnect(Scenes.scene_ready, patch_mario)
		return Command.ExecuteResult.new("Success, Disabled")
		

func patch_mario() -> void:
	Data.values.time = -1
