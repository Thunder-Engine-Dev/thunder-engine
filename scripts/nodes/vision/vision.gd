extends VisibleOnScreenNotifier2D

@export var new_rect: Rect2 = Rect2(Vector2(-512, -512), Vector2(1024, 1024))


func _ready() -> void:
	screen_entered.connect(
		func() -> void:
			rect = new_rect
	)
