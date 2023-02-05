# Base level node

#@tool
@icon("./icon.svg")
extends Stage2D
class_name Level

@export var time: int = 360

@export_enum("Nothing", "Death", "Wrap") var falling_below_screen_action: int = 1


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		prepare_template()
		return
	
	Data.values.time = time

# Adding neccessary nodes to our level scene
func prepare_template() -> void:
	pass


func _physics_process(delta):
	if Thunder._current_player.position.y > 512: # TEMP
		match falling_below_screen_action:
			1:
				Thunder._current_player.kill()
			2:
				Thunder._current_player.position.y -= 608
		
