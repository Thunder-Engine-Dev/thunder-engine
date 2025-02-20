extends Command

static func register() -> Command:
	return new().set_name("items").set_description("Display contents of item boxes.")

func execute(args:Array) -> Command.ExecuteResult:
	
	# res://engine/objects/bumping_blocks/question_block/question_block.gd
	Console.item_display_shown = !Console.item_display_shown
	return Command.ExecuteResult.new("Success, restart the level to have effect")
