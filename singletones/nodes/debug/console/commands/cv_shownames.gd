extends Command

static func register() -> Command:
	return new().set_name("cv_shownames").set_description("Show object's name & class under mouse cursor.")

func execute(args:Array) -> Command.ExecuteResult:
	
	Console.cv.object_names_shown = !Console.cv.object_names_shown
	if Console.cv.object_names_shown:
		if !GlobalViewport.has_node("DebugMouseLabel"):
			var mlabel = load("res://engine/singletones/nodes/viewport/debug_mouse_label.tscn").instantiate()
			GlobalViewport.add_child(mlabel, true)
	
	return Command.ExecuteResult.new("Success")
