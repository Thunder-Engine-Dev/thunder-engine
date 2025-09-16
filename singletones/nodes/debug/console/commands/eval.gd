extends Command

static func register() -> Command:
	return new().set_name("eval").add_param("code", TYPE_STRING).set_description("Evaluates a gdscript snippet").set_debug()

func execute(args:Array) -> Command.ExecuteResult:
	var msg: String = ""
	for w in args:
		msg += w + ' '
	
	var expression = Expression.new()
	var error = expression.parse(msg, [])
	
	if error != OK:
		return Command.ExecuteResult.new("[color=red]Failed to parse the snippet[/color]\n%s" % expression.get_error_text())
	
	var execution_result = expression.execute([], Thunder)
	if expression.has_execute_failed():
		return Command.ExecuteResult.new("[color=red]Failed to execute the snippet[/color]\n%s" % expression.get_error_text())

	return Command.ExecuteResult.new(str(execution_result))
