extends Command

static func register() -> Command:
	return new().set_name("reloadskins") \
	.set_description("Updates skins from the file system immediately") \
	.set_not_cheat()

func execute(args:Array) -> Command.ExecuteResult:
	var _tex = SkinsManager.load_external_textures()
	return Command.ExecuteResult.new(_tex)
