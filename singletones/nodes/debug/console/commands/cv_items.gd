extends Command

static func register() -> Command:
	return new().set_name("cv_items").set_description("Display contents of item boxes.")

func execute(args:Array) -> Command.ExecuteResult:
	
	# res://engine/objects/bumping_blocks/question_block/question_block.gd
	Console.cv.item_display_shown = !Console.cv.item_display_shown
	return Command.ExecuteResult.new("Success, restart the level to have effect")
