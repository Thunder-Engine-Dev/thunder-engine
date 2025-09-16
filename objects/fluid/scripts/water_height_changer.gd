extends "res://engine/objects/detectors/player_detection.gd"

@export var change_by: float = 0

func _ready():
	super()
	player_enter.connect(get_parent().set_water_height.bind(change_by))
	
