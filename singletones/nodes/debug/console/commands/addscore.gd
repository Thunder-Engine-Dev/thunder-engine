extends Command

static func register() -> Command:
	return new().set_name("addscore").add_param("amount", TYPE_INT, false).set_description("Adds score.")

func execute(args:Array) -> Command.ExecuteResult:
	if args.is_empty() || is_nan(float(args[0])):
		return Command.ExecuteResult.new("[color=red]Provide a valid amount of score.[/color]")
	else:
		Thunder.add_score(args[0])
	return Command.ExecuteResult.new("Success")
	
