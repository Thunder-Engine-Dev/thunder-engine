extends Command

static func register() -> Command:
	return new().set_name("checkpoint") \
	.add_param("index", TYPE_INT) \
	.set_description("Sets level checkpoint. -1 means no checkpoint, 0 is the first, etc.")

func execute(args:Array) -> Command.ExecuteResult:
	Data.values.checkpoint = int(args[0])
	return Command.ExecuteResult.new("Success")
