extends Command

static func register() -> Command:
	return new().set_name("eval").add_param("code", TYPE_STRING).set_description("Evaluates a gdscript snippet. [color=red]This can crash the game![/color]")

func execute(args:Array) -> Command.ExecuteResult:
	var msg: String
	for w in args:
		msg += w + ' '
	
	var script = GDScript.new()
	script.source_code = "func a():return %s" % msg
	script.reload()
	
	var result: Command.ExecuteResult = Command.ExecuteResult.new(script.new().call("a"))
	return result
