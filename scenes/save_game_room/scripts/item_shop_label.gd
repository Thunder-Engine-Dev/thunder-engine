extends InputRichTextLabel

@export var revamp_extra_text: String = "PRESS {m_up} TO SELECT AN ITEM."

func _ready() -> void:
	if input_template.is_empty():
		input_template = text
	if SettingsManager.get_tweak("revamp_item_shop", false):
		input_template += "\n\n" + revamp_extra_text
	super()
