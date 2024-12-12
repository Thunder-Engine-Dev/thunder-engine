extends "res://engine/objects/signs/sign_help_key_formatter.gd"

@export var revamp_extra_text: String = "PRESS %s TO SELECT AN ITEM."

func _ready() -> void:
	if SettingsManager.get_tweak("revamped_item_shop", true):
		_template += "
" + revamp_extra_text
		super()
